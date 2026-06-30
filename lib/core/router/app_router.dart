import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/kasir/kasir_screen.dart';
import '../../features/kasir/checkout_screen.dart';
import '../../features/kasir/receipt_screen.dart';
import '../../features/kasir/reservation_screen.dart';
import '../../features/riwayat/riwayat_screen.dart';
import '../../features/riwayat/order_detail_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/produk/produk_screen.dart';
import '../../features/produk/produk_form_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/manage_users_screen.dart';
import '../../features/settings/subscription_screen.dart';
import '../../features/settings/printer_screen.dart';
import '../../features/settings/edit_receipt_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/settings/notification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/otp', builder: (ctx, state) {
        final email = state.extra as String? ?? '';
        return OtpScreen(email: email);
      }),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/kasir', builder: (_, _) => const KasirScreen()),
          GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
          GoRoute(path: '/receipt', builder: (ctx, _) => const ReceiptScreen()),
          GoRoute(path: '/reservasi', builder: (_, _) => const ReservationScreen()),
          GoRoute(path: '/riwayat', builder: (_, _) => const RiwayatScreen()),
          GoRoute(path: '/riwayat/:id', builder: (_, state) {
            final id = state.pathParameters['id']!;
            return OrderDetailScreen(orderId: id);
          }),
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/produk', builder: (_, _) => const ProdukScreen()),
          GoRoute(path: '/produk/baru', builder: (_, _) => const ProdukFormScreen()),
          GoRoute(path: '/produk/:id/edit', builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ProdukFormScreen(productId: id);
          }),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: '/settings/users', builder: (_, _) => const ManageUsersScreen()),
          GoRoute(path: '/settings/subscription', builder: (_, _) => const SubscriptionScreen()),
          GoRoute(path: '/settings/printer', builder: (_, _) => const PrinterScreen()),
          GoRoute(path: '/settings/receipt', builder: (_, _) => const EditReceiptScreen()),
          GoRoute(path: '/settings/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/notifications', builder: (_, _) => const NotificationScreen()),
        ],
      ),
    ],
  );
});
