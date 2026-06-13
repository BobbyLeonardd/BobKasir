import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bobkasir/core/network/dio_client.dart';
import 'package:bobkasir/core/storage/app_storage.dart';
import 'package:bobkasir/features/sync/data/sync_provider.dart';

/// Canned HTTP adapter so we can exercise DefaultSyncRepository.push (the real
/// Dio glue + response parsing) without a server.
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

SyncQueueItem _item() => SyncQueueItem(
      syncId: 's1',
      localId: 'o1',
      deviceId: 'd1',
      type: SyncItemType.order,
      payload: const {'local_order_id': 'o1'},
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppStorage.instance.init();
    DioClient.instance.init();
  });

  group('DefaultSyncRepository.push', () {
    test('parses a synced response and adopts the server order number', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(
        200,
        jsonEncode({
          'success': true,
          'data': {
            'results': [
              {'status': 'synced', 'order_number': 'BK-20260611-0001'},
            ],
          },
        }),
      );

      final outcome = await const DefaultSyncRepository().push(_item());

      expect(outcome.success, isTrue);
      expect(outcome.orderNumber, 'BK-20260611-0001');
    });

    test('treats already_synced as success (idempotent replay)', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(
        200,
        jsonEncode({
          'success': true,
          'data': {
            'results': [
              {'status': 'already_synced'},
            ],
          },
        }),
      );

      final outcome = await const DefaultSyncRepository().push(_item());

      expect(outcome.success, isTrue);
    });

    test('returns failure when the server reports a failed item', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(
        200,
        jsonEncode({
          'success': true,
          'data': {
            'results': [
              {'status': 'failed', 'error': 'stok bentrok'},
            ],
          },
        }),
      );

      final outcome = await const DefaultSyncRepository().push(_item());

      expect(outcome.success, isFalse);
      expect(outcome.error, 'stok bentrok');
    });

    test('returns failure on an HTTP error', () async {
      DioClient.instance.dio.httpClientAdapter = _FakeAdapter(500, '{}');

      final outcome = await const DefaultSyncRepository().push(_item());

      expect(outcome.success, isFalse);
      expect(outcome.error, isNotNull);
    });
  });
}
