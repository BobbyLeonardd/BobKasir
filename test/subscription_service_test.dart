import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bobkasir/core/network/dio_client.dart';
import 'package:bobkasir/core/storage/app_storage.dart';
import 'package:bobkasir/features/subscription/data/subscription_provider.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppStorage.instance.init();
    DioClient.instance.init();
  });

  group('SubscriptionStatus.fromJson', () {
    test('parses status, plan and expiry', () {
      final s = SubscriptionStatus.fromJson({
        'status': 'active',
        'plan': 'monthly',
        'expired_at': '2026-07-11T10:00:00.000Z',
        'is_active': true,
      });
      expect(s.status, 'active');
      expect(s.plan, 'monthly');
      expect(s.isActive, isTrue);
      expect(s.effectiveExpiry, isNotNull);
    });

    test('falls back to trial expiry when no paid expiry', () {
      final s = SubscriptionStatus.fromJson({
        'status': 'trial',
        'trial_expired_at': '2026-06-18T10:00:00.000Z',
        'is_active': true,
      });
      expect(s.expiredAt, isNull);
      expect(s.effectiveExpiry, isNotNull);
    });
  });

  group('SubscriptionApiService.checkout', () {
    test('parses snap token and url', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(
        200,
        jsonEncode({
          'success': true,
          'data': {
            'snap_token': 'SNAP-123',
            'order_id': 'BK-SUB-XYZ',
            'client_key': 'Mid-client-abc',
            'snap_url': 'https://app.sandbox.midtrans.com/snap/snap.js',
          },
        }),
      );

      final result = await SubscriptionApiService.checkout('monthly');

      expect(result.snapToken, 'SNAP-123');
      expect(result.orderId, 'BK-SUB-XYZ');
      expect(result.snapUrl, contains('snap.js'));
    });

    test('throws when the server reports failure', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(
        500,
        jsonEncode({'success': false, 'message': 'Midtrans error'}),
      );

      expect(
        () => SubscriptionApiService.checkout('weekly'),
        throwsA(isA<Object>()),
      );
    });
  });
}
