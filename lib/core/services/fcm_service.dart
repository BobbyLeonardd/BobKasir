import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../repositories/notification_repository.dart';

final fcmServiceProvider = Provider((ref) => FcmService(ref));

class FcmService {
  final Ref _ref;
  FcmService(this._ref);

  /// Call once after login to request permission and register token.
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS requires explicit ask)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token and register with backend
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      await _registerToken(newToken);
    });

    // Handle foreground messages — show local notification or banner
    FirebaseMessaging.onMessage.listen((message) {
      // Riverpod invalidate so notification badge updates
      _ref.invalidate(notificationsProvider);
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _ref.read(notificationRepositoryProvider).registerDeviceToken(token, platform: platform);
    } catch (_) {
      // Non-fatal — token registration failure should not crash the app
    }
  }
}
