import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/cashier/presentation/screens/cashier_screen.dart';
import '../../features/cashier/presentation/screens/checkout_screen.dart';
import '../../features/cashier/presentation/screens/payment_screen.dart';
import '../../features/cashier/presentation/screens/receipt_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/products/domain/product.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/shift/presentation/screens/shift_screen.dart';
import '../../features/shift/presentation/screens/open_shift_screen.dart';
import '../../features/shift/presentation/screens/close_shift_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/printer_settings_screen.dart';
import '../../features/settings/presentation/screens/receipt_settings_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/auth/presentation/screens/main_scaffold.dart';
import '../../features/settings/presentation/screens/cash_drawer_screen.dart';
import '../../features/settings/presentation/screens/tax_service_screen.dart';
import '../../features/settings/presentation/screens/discount_screen.dart';
import '../../features/stock/presentation/screens/stock_screen.dart';
import '../../features/openbill/presentation/screens/open_bill_screen.dart';
import '../../features/openbill/presentation/screens/open_bill_detail_screen.dart';
import '../../features/reservation/presentation/screens/reservation_screen.dart';
import '../../features/outlet/presentation/screens/outlet_screen.dart';
import '../../features/report/presentation/screens/report_screen.dart';
import '../../features/promo/presentation/screens/promo_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_display_screen.dart';

import '../../features/sync/presentation/screens/sync_status_screen.dart';
import '../../features/settings/presentation/screens/manage_roles_screen.dart';

// Routes class — use 'class' not 'abstract class' so static const works
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const cashier = '/cashier';
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const receipt = '/receipt';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const products = '/products';
  static const productForm = '/products/form';
  static const dashboard = '/dashboard';
  static const shift = '/shift';
  static const openShift = '/shift/open';
  static const closeShift = '/shift/close';
  static const settings = '/settings';
  static const about = '/settings/about';
  static const printerSettings = '/settings/printer';
  static const receiptSettings = '/settings/receipt';
  static const subscription = '/subscription';
  static const syncStatus = '/sync';
  static const manageRoles = '/settings/roles';
  static const cashDrawer = '/settings/cash-drawer';
  static const taxService = '/settings/tax-service';
  static const discount = '/settings/discount';
  static const stock = '/stock';
  static const openBill = '/open-bill';
  static const openBillDetail = '/open-bill/:id';
  static const reservation = '/reservation';
  static const outlet = '/settings/outlet';
  static const report = '/report';
  static const promo = '/settings/promo';
  static const kitchenDisplay = '/kitchen';
}

/// Pure auth/redirect logic — extracted so it can be unit-tested.
/// [path] must be the location path WITHOUT query string (state.uri.path).
String? authRedirect({
  required bool isLoading,
  required bool isAuthenticated,
  UserRole? role,
  required String path,
}) {
  // Still checking auth — stay at splash.
  if (isLoading) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // Not logged in → only allow auth routes (exact match; '/' must NOT
  // match every path via startsWith).
  const publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.verifyEmail,
  ];
  if (!isAuthenticated && !publicRoutes.contains(path)) {
    return AppRoutes.login;
  }

  // Already logged in → skip auth pages.
  if (isAuthenticated &&
      (path == AppRoutes.login || path == AppRoutes.register)) {
    return AppRoutes.cashier;
  }

  // Role-based guards.
  if (isAuthenticated && role != null) {
    if (!role.canViewDashboard && path.startsWith(AppRoutes.dashboard)) {
      return AppRoutes.cashier;
    }
    if (!role.canViewProducts && path.startsWith(AppRoutes.products)) {
      return AppRoutes.cashier;
    }
    if (!role.canManageSubscription &&
        path.startsWith(AppRoutes.subscription)) {
      return AppRoutes.settings;
    }
    if (!role.canManageRoles && path.startsWith(AppRoutes.manageRoles)) {
      return AppRoutes.settings;
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => authRedirect(
      isLoading: authState.isLoading,
      isAuthenticated: authState.isAuthenticated,
      role: authState.user?.role,
      path: state.uri.path,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (c, s) => _fade(s, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (c, s) => _fade(s, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (c, s) => _fade(s, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        pageBuilder: (c, s) => _fade(
          s,
          VerifyEmailScreen(
            email: s.uri.queryParameters['email'] ?? '',
          ),
        ),
      ),

      // ── Authenticated shell ──
      ShellRoute(
        builder: (c, s, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.cashier,
            pageBuilder: (c, s) => _fade(s, const CashierScreen()),
          ),
          GoRoute(
            path: AppRoutes.orders,
            pageBuilder: (c, s) => _fade(s, const OrdersScreen()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (c, s) => _fade(s, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (c, s) => _fade(s, const ProductsScreen()),
          ),
          GoRoute(
            path: AppRoutes.shift,
            pageBuilder: (c, s) => _fade(s, const ShiftScreen()),
          ),
          GoRoute(
            path: AppRoutes.stock,
            pageBuilder: (c, s) => _fade(s, const StockScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (c, s) => _fade(s, const SettingsScreen()),
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ──
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (c, s) => _slide(s, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.payment,
        pageBuilder: (c, s) => _slide(s, const PaymentScreen()),
      ),
      GoRoute(
        path: AppRoutes.receipt,
        pageBuilder: (c, s) => _fade(s, const ReceiptScreen()),
      ),
      GoRoute(
        path: '/orders/:id',
        pageBuilder: (c, s) => _slide(
          s,
          OrderDetailScreen(orderId: s.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.productForm,
        pageBuilder: (c, s) => _slide(
          s,
          ProductFormScreen(
            product: s.extra is Product ? s.extra as Product : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.openShift,
        pageBuilder: (c, s) => _slide(s, const OpenShiftScreen()),
      ),
      GoRoute(
        path: AppRoutes.closeShift,
        pageBuilder: (c, s) => _slide(s, const CloseShiftScreen()),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (c, s) => _fade(s, const AboutScreen()),
      ),
      GoRoute(
        path: AppRoutes.printerSettings,
        pageBuilder: (c, s) => _fade(s, const PrinterSettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.receiptSettings,
        pageBuilder: (c, s) => _fade(s, const ReceiptSettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        pageBuilder: (c, s) => _fade(s, const SubscriptionScreen()),
      ),
      GoRoute(
        path: AppRoutes.syncStatus,
        pageBuilder: (c, s) => _fade(s, const SyncStatusScreen()),
      ),
      GoRoute(
        path: AppRoutes.manageRoles,
        pageBuilder: (c, s) => _fade(s, const ManageRolesScreen()),
      ),
      GoRoute(
        path: AppRoutes.cashDrawer,
        pageBuilder: (c, s) => _fade(s, const CashDrawerScreen()),
      ),
      GoRoute(
        path: AppRoutes.taxService,
        pageBuilder: (c, s) => _fade(s, const TaxServiceScreen()),
      ),
      GoRoute(
        path: AppRoutes.discount,
        pageBuilder: (c, s) => _fade(s, const DiscountScreen()),
      ),
      GoRoute(
        path: AppRoutes.openBill,
        pageBuilder: (c, s) => _fade(s, const OpenBillScreen()),
      ),
      GoRoute(
        path: '/open-bill/:id',
        pageBuilder: (c, s) => _slide(
          s,
          OpenBillDetailScreen(billId: s.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.reservation,
        pageBuilder: (c, s) => _fade(s, const ReservationScreen()),
      ),
      GoRoute(
        path: AppRoutes.outlet,
        pageBuilder: (c, s) => _fade(s, const OutletScreen()),
      ),
      GoRoute(
        path: AppRoutes.report,
        pageBuilder: (c, s) => _fade(s, const ReportScreen()),
      ),
      GoRoute(
        path: AppRoutes.promo,
        pageBuilder: (c, s) => _fade(s, const PromoScreen()),
      ),
      GoRoute(
        path: AppRoutes.kitchenDisplay,
        pageBuilder: (c, s) => _fade(s, const KitchenDisplayScreen()),
      ),
    ],
  );
});

/// Fade Through — premium, no sliding
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    ),
  );
}

/// Shared Axis — vertical slide for detail/form
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) {
      final tween = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: SlideTransition(position: animation.drive(tween), child: child),
      );
    },
  );
}
