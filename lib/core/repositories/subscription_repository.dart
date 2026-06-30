import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final subscriptionRepositoryProvider =
    Provider((ref) => SubscriptionRepository(ref.read(apiClientProvider)));

class SubscriptionRepository {
  final ApiClient _api;
  SubscriptionRepository(this._api);

  Future<Map<String, dynamic>> getCurrent() async {
    final resp = await _api.get('/subscriptions/current');
    return resp.data as Map<String, dynamic>;
  }

  /// Returns Midtrans snap token + redirect_url
  Future<Map<String, dynamic>> checkout(String package) async {
    final resp = await _api.post('/subscriptions/checkout', data: {'package': package});
    return resp.data as Map<String, dynamic>;
  }

  /// Manual bank transfer — returns instruction data
  Future<Map<String, dynamic>> manualPayment(String package) async {
    final resp = await _api.post('/subscriptions/manual', data: {'package': package});
    return resp.data as Map<String, dynamic>;
  }

  Future<void> cancel() async {
    await _api.post('/subscriptions/cancel');
  }
}
