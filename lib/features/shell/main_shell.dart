import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/offline_banner.dart';

// Unread notification count provider
final unreadNotifCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Kasir', path: '/kasir'),
    _TabItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Riwayat', path: '/riwayat'),
    _TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Dashboard', path: '/dashboard', ownerAdminOnly: true),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Pengaturan', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final location = GoRouterState.of(context).uri.toString();
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final visibleTabs = _tabs.where((t) {
      if (t.ownerAdminOnly) return user?.canViewDashboard ?? false;
      return true;
    }).toList();

    int currentIndex = visibleTabs.indexWhere((t) => location.startsWith(t.path));
    if (currentIndex < 0) currentIndex = 0;

    void onTab(int i) => context.go(visibleTabs[i].path);

    final notifBell = _NotifBell();

    if (isTablet) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(user?.tenant?.shopName ?? 'BobKasir', style: const TextStyle(fontWeight: FontWeight.w600)),
          actions: [notifBell, const SizedBox(width: 8)],
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: onTab,
                    labelType: NavigationRailLabelType.all,
                    destinations: visibleTabs.map((t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    )).toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(user?.tenant?.shopName ?? 'BobKasir', style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [notifBell, const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: visibleTabs.map((t) => NavigationDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final bool ownerAdminOnly;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.path, this.ownerAdminOnly = false});
}

class _NotifBell extends ConsumerWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotifCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notifikasi',
        ),
        if (count > 0)
          Positioned(
            right: 6, top: 6,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
