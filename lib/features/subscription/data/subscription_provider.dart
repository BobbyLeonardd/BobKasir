import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class SubscriptionStatus {
  final String status; // trial / active / expired / pending_payment / ...
  final String? plan;
  final DateTime? expiredAt;
  final DateTime? trialExpiredAt;
  final bool isActive;

  const SubscriptionStatus({
    required this.status,
    this.plan,
    this.expiredAt,
    this.trialExpiredAt,
    this.isActive = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) {
    DateTime? parse(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return SubscriptionStatus(
      status: j['status'] as String? ?? 'expired',
      plan: j['plan'] as String?,
      expiredAt: parse(j['expired_at']),
      trialExpiredAt: parse(j['trial_expired_at']),
      isActive: j['is_active'] as bool? ?? false,
    );
  }

  /// Best end date to show the user (paid expiry, else trial expiry).
  DateTime? get effectiveExpiry => expiredAt ?? trialExpiredAt;
}

class CheckoutResult {
  final String snapToken;
  final String orderId;
  final String snapUrl;
  final String clientKey;

  const CheckoutResult({
    required this.snapToken,
    required this.orderId,
    required this.snapUrl,
    required this.clientKey,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        snapToken: j['snap_token'] as String? ?? '',
        orderId: j['order_id'] as String? ?? '',
        snapUrl: j['snap_url'] as String? ?? '',
        clientKey: j['client_key'] as String? ?? '',
      );
}

class SubscriptionApiService {
  static Dio get _dio => DioClient.instance.dio;

  static Future<SubscriptionStatus?> status() async {
    try {
      final res = await _dio.get('/subscription/status');
      if (res.data['success'] == true && res.data['data'] != null) {
        return SubscriptionStatus.fromJson(
            Map<String, dynamic>.from(res.data['data']));
      }
    } catch (_) {}
    return null;
  }

  /// Starts a Midtrans transaction for [plan] ('weekly'|'monthly').
  /// Throws [DioException] on failure so the UI can surface the error.
  static Future<CheckoutResult> checkout(String plan) async {
    final res = await _dio.post('/subscription/checkout', data: {'plan': plan});
    if (res.data['success'] == true && res.data['data'] != null) {
      return CheckoutResult.fromJson(Map<String, dynamic>.from(res.data['data']));
    }
    throw Exception(res.data['message'] ?? 'Gagal membuat transaksi');
  }

  static Future<List<Map<String, dynamic>>> history() async {
    try {
      final res = await _dio.get('/subscription/history');
      final data = res.data['data'];
      if (data is List) {
        return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    } catch (_) {}
    return const [];
  }
}

final subscriptionStatusProvider =
    FutureProvider<SubscriptionStatus?>((ref) => SubscriptionApiService.status());

final subscriptionHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>(
        (ref) => SubscriptionApiService.history());
