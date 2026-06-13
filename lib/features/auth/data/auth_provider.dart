import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/network/session_events.dart';
import 'auth_api_service.dart';

// ─────────────────────────────────────────────
// Auth State
// ─────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  UserRole? get role => user?.role;
}

// ─────────────────────────────────────────────
// Auth Notifier
// ─────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<void>? _unauthorizedSub;

  @override
  AuthState build() {
    // Server rejected the token (401) → drop the in-memory session (H3).
    _unauthorizedSub = SessionEvents.instance.onUnauthorized.listen((_) {
      if (state.isAuthenticated) logout();
    });
    ref.onDispose(() => _unauthorizedSub?.cancel());

    // Restore from storage on startup
    _restoreSession();
    return const AuthState.loading();
  }

  void _restoreSession() {
    final storage = AppStorage.instance;
    final token = storage.token;
    final userId = storage.userId;
    final role = storage.userRole;

    if (token != null && userId != null && role != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: userId,
          name: storage.userName ?? '',
          email: storage.userEmail ?? '',
          role: UserRoleExt.fromString(role),
          avatar: storage.userAvatar,
          businessId: storage.businessId ?? '',
          businessName: storage.businessName ?? '',
        ),
      );
      // Validate the restored token against the server (H4). A 401 is handled
      // globally by the Dio interceptor → onUnauthorized → logout. Network
      // failures are ignored so the app still works offline.
      _validateSession();
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Pings /auth/me; refreshes the cached user (role/subscription may change).
  Future<void> _validateSession() async {
    final user = await AuthApiService.me();
    if (user != null && state.isAuthenticated) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    }
  }

  /// Called after successful login — saves session and updates state
  Future<void> onLoginSuccess({
    required String token,
    required UserModel user,
  }) async {
    await AppStorage.instance.saveUserSession(
      token: token,
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role.name,
      avatar: user.avatar,
      businessId: user.businessId,
      businessName: user.businessName,
    );
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await AuthApiService.logout(); // best-effort server-side token revoke
    await AppStorage.instance.clearSession();
    state = const AuthState.unauthenticated();
  }

  void updateUser(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Convenience selectors
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).user?.role;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
