import 'package:flutter_test/flutter_test.dart';
import 'package:bobkasir/core/router/app_router.dart';
import 'package:bobkasir/features/auth/domain/user_model.dart';

/// Guards the auth redirect logic (C1). The previous implementation let any
/// path through for unauthenticated users because '/' (splash) was matched with
/// startsWith. These tests pin the corrected behaviour.
void main() {
  group('authRedirect — unauthenticated', () {
    test('protected route redirects to login', () {
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: false,
            path: AppRoutes.cashier),
        AppRoutes.login,
      );
    });

    test('deep protected route also redirects to login', () {
      expect(
        authRedirect(
            isLoading: false, isAuthenticated: false, path: '/settings/roles'),
        AppRoutes.login,
      );
    });

    test('public auth routes are allowed', () {
      for (final p in [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      ]) {
        expect(
          authRedirect(isLoading: false, isAuthenticated: false, path: p),
          isNull,
          reason: '$p should be public',
        );
      }
    });
  });

  group('authRedirect — loading', () {
    test('non-splash path is sent to splash while loading', () {
      expect(
        authRedirect(
            isLoading: true, isAuthenticated: false, path: AppRoutes.cashier),
        AppRoutes.splash,
      );
    });

    test('splash stays during loading', () {
      expect(
        authRedirect(
            isLoading: true, isAuthenticated: false, path: AppRoutes.splash),
        isNull,
      );
    });
  });

  group('authRedirect — authenticated role guards', () {
    test('logged-in user is bounced off the login page', () {
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.owner,
            path: AppRoutes.login),
        AppRoutes.cashier,
      );
    });

    test('karyawan cannot open dashboard or products', () {
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.karyawan,
            path: AppRoutes.dashboard),
        AppRoutes.cashier,
      );
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.karyawan,
            path: AppRoutes.products),
        AppRoutes.cashier,
      );
    });

    test('manager cannot manage subscription; owner can see dashboard', () {
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.manager,
            path: AppRoutes.subscription),
        AppRoutes.settings,
      );
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.owner,
            path: AppRoutes.dashboard),
        isNull,
      );
    });

    test('only owner may manage roles', () {
      expect(
        authRedirect(
            isLoading: false,
            isAuthenticated: true,
            role: UserRole.karyawan,
            path: AppRoutes.manageRoles),
        AppRoutes.settings,
      );
    });
  });
}
