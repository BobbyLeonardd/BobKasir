import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../features/auth/data/auth_provider.dart';
import '../../../../features/auth/domain/user_model.dart';
import '../../../../features/sync/data/sync_provider.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? UserRole.karyawan;
    final isOnline = ref.watch(isOnlineProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider);

    ref.watch(themeProvider); // watch to trigger rebuild on theme change

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // Profile section
          _ProfileHeader(user: user, isDark: isDark),
          const SizedBox(height: AppSpacing.sm),

          // Sync status tile
          _SectionHeader(label: 'SINKRONISASI', isDark: isDark),
          _SettingsTile(
            icon: unsyncedCount > 0
                ? Icons.sync_problem_outlined
                : Icons.cloud_done_outlined,
            title: 'Status Sinkronisasi',
            isDark: isDark,
            subtitle: isOnline
                ? (unsyncedCount > 0
                    ? '$unsyncedCount data belum sinkron'
                    : 'Semua data tersinkron')
                : 'Offline — data tersimpan lokal',
            trailing: unsyncedCount > 0
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unsyncedCount',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : null,
            onTap: () => context.push(AppRoutes.syncStatus),
          ),
          const _Divider(),

          // Appearance
          _SectionHeader(label: 'TAMPILAN', isDark: isDark),
          _SettingsTile(
            icon: isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            title: isDark ? 'Ivory Elegance (Terang)' : 'Midnight Obsidian (Gelap)',
            subtitle: isDark ? 'Beralih ke tema terang' : 'Beralih ke tema gelap',
            isDark: isDark,
            trailing: Switch(
              value: isDark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggle(),
              activeThumbColor:
                  isDark ? AppColors.champagneGold : AppColors.charcoal,
              activeTrackColor: isDark
                  ? AppColors.champagneGold.withValues(alpha: 0.3)
                  : AppColors.charcoal.withValues(alpha: 0.3),
            ),
          ),
          const _Divider(),

          // Kasir settings
          _SectionHeader(label: 'KASIR', isDark: isDark),
          _SettingsTile(
            icon: Icons.print_outlined,
            title: 'Printer Bluetooth',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.printerSettings),
          ),
          _SettingsTile(
            icon: Icons.open_in_full_outlined,
            title: 'Cash Drawer',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.cashDrawer),
          ),
          if (role.canEditReceipt)
            _SettingsTile(
              icon: Icons.receipt_outlined,
              title: 'Template Struk',
              isDark: isDark,
              onTap: () => context.push(AppRoutes.receiptSettings),
            ),
          const _Divider(),

          // Business settings (Owner/Manager only)
          if (role.canManageTaxDiscount) ...[
            _SectionHeader(label: 'BISNIS', isDark: isDark),
            _SettingsTile(
              icon: Icons.percent_outlined,
              title: 'Pajak & Service Charge',
              isDark: isDark,
              onTap: () => context.push(AppRoutes.taxService),
            ),
            _SettingsTile(
              icon: Icons.local_offer_outlined,
              title: 'Diskon',
              isDark: isDark,
              onTap: () => context.push(AppRoutes.discount),
            ),
          _SettingsTile(
            icon: Icons.store_outlined,
            title: 'Kelola Outlet',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.outlet),
          ),
          _SettingsTile(
            icon: Icons.local_offer_outlined,
            title: 'Promo & Voucher',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.promo),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_outlined,
            title: 'Laporan & Export',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.report),
          ),
          _SettingsTile(
            icon: Icons.restaurant_outlined,
            title: 'Kitchen Display',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.kitchenDisplay),
          ),
            const _Divider(),
          ],

          // Account & Subscription (Owner only)
          _SectionHeader(label: 'AKUN', isDark: isDark),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            isDark: isDark,
            onTap: () {},
          ),
          if (role.canManageRoles)
            _SettingsTile(
              icon: Icons.group_outlined,
              title: 'Kelola Tim',
              isDark: isDark,
              onTap: () => context.push(AppRoutes.manageRoles),
            ),
          if (role.canManageSubscription)
            _SettingsTile(
              icon: Icons.card_membership_outlined,
              title: 'Langganan',
              isDark: isDark,
              onTap: () => context.push(AppRoutes.subscription),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Trial',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const _Divider(),

          // App info
          _SectionHeader(label: 'APLIKASI', isDark: isDark),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang BobKasir',
            isDark: isDark,
            onTap: () => context.push(AppRoutes.about),
          ),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Keluar',
            isDark: isDark,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (ctx.mounted) context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _ProfileHeader({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final name = user?.name ?? 'User';
    final email = user?.email ?? '';
    final roleLabel = user?.role.label ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isDark
                ? AppColors.champagneGold.withValues(alpha: 0.1)
                : AppColors.charcoal.withValues(alpha: 0.08),
            backgroundImage: user?.avatar != null
                ? NetworkImage(user!.avatar!) as ImageProvider
                : null,
            child: user?.avatar == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.champagneGold
                          : AppColors.charcoal,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '$email · $roleLabel',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.ashGray,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.md,
        AppSpacing.pageH,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.ashGray,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.isDark,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.danger
        : (isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary);
    final iconColor = isDestructive
        ? AppColors.danger
        : (isDark ? AppColors.darkTextSecondary : AppColors.ashGray);

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge
            .copyWith(color: color, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption)
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: AppSpacing.pageH,
      endIndent: AppSpacing.pageH,
    );
  }
}
