import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository(ref.read(apiClientProvider)));

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: j['id'].toString(),
      title: j['title'] ?? '',
      body: j['body'] ?? '',
      isRead: j['read_at'] != null,
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationRepository {
  final ApiClient _api;
  NotificationRepository(this._api);

  Future<List<NotificationModel>> getAll() async {
    final resp = await _api.get('/notifications');
    final list = resp.data['data'] as List;
    return list.map((j) => NotificationModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _api.post('/notifications/read/$id');
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    await _api.post('/device-tokens', data: {
      'token': token,
      'platform': platform,
    });
  }
}
