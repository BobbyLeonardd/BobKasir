import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../features/auth/data/auth_provider.dart';
import '../../../../features/auth/domain/user_model.dart';

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final bool Function(UserRole) allowed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.allowed,
  });
}

const _allTabs = [
  _NavItem(
    icon: Icons.point_of_sale_outlined,
    label: 'Kasir',
    route: AppRoutes.cashier,
    allowed: _alwaysTrue,
  ),
  _NavItem(
    icon: Icons.receipt_long_outlined,
    label: 'Riwayat',
    route: AppRoutes.orders,
    allowed: _alwaysTrue,
  ),
  _NavItem(
    icon: Icons.bar_chart_outlined,
    label: 'Dashboard',
    route: AppRoutes.dashboard,
    allowed: _canDashboard,
  ),
  _NavItem(
    icon: Icons.inventory_2_outlined,
    label: 'Produk',
    route: AppRoutes.products,
    allowed: _canProducts,
  ),
  _NavItem(
    icon: Icons.layers_outlined,
    label: 'Stok',
    route: AppRoutes.stock,
    allowed: _canStok,
  ),
  _NavItem(
    icon: Icons.tune_outlined,
    label: 'Lainnya',
    route: AppRoutes.settings,
    allowed: _alwaysTrue,
  ),
];

bool _alwaysTrue(UserRole _) => true;
bool _canDashboard(UserRole r) => r.canViewDashboard;
bool _canProducts(UserRole r) => r.canViewProducts;
bool _canStok(UserRole r) => r.canViewStok;

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(currentRoleProvider) ?? UserRole.karyawan;
    final isOffline = ref.watch(isOfflineProvider);

    final visibleTabs =
        _allTabs.where((t) => t.allowed(role)).toList();

    final currentIndex = _locationIndex(location, visibleTabs);

    return Scaffold(
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _PremiumNavBar(
        tabs: visibleTabs,
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: (i) => context.go(visibleTabs[i].route),
      ),
    );
  }

  int _locationIndex(String location, List<_NavItem> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) return i;
    }
    return 0;
  }
}

class _PremiumNavBar extends StatelessWidget {
  final List<_NavItem> tabs;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeColor =
        isDark ? AppColors.champagneGold : AppColors.charcoal;
    final inactiveColor =
        isDark ? AppColors.darkTextSecondary : AppColors.ashGray;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 22,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 4 : 0,
                        height: isActive ? 4 : 0,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
