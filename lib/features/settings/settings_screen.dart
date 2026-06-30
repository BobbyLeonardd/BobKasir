import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (user?.canManageUsers == true || user?.canManageSubscription == true) ...[
            _SectionHeader('Toko'),
            if (user?.canManageUsers == true)
              _SettingsTile(icon: Icons.group_outlined, title: 'Kelola Akun & Role', onTap: () => context.push('/settings/users')),
            if (user?.canManageSubscription == true)
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Langganan',
                subtitle: sub.status == SubscriptionStatus.trial ? 'Trial — ${sub.expiresAt != null ? sub.expiresAt!.difference(DateTime.now()).inDays : 0} hari lagi' : sub.status.name,
                onTap: () => context.push('/settings/subscription'),
              ),
          ],
          _SectionHeader('Perangkat'),
          _SettingsTile(icon: Icons.print_outlined, title: 'Printer & Cash Drawer', onTap: () => context.push('/settings/printer')),
          if (user?.canManageProducts == true)
            _SettingsTile(icon: Icons.receipt_outlined, title: 'Edit Template Struk', onTap: () => context.push('/settings/receipt')),
          _SectionHeader('Akun'),
          _SettingsTile(icon: Icons.person_outline, title: 'Profil Saya', subtitle: user?.name, onTap: () => context.push('/settings/profile')),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tampilan',
            subtitle: ref.watch(themeProvider) == ThemeMode.dark ? 'Gelap' : ref.watch(themeProvider) == ThemeMode.light ? 'Terang' : 'Ikut sistem',
            onTap: () => showModalBottomSheet(context: context, builder: (_) => _ThemeSheet()),
          ),
          const Divider(),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Keluar',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface3, letterSpacing: 0.5)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.onTap, this.iconColor, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.onSurface2, size: 22),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.onSurface, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.onSurface3)) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.onSurface3) : null,
      onTap: onTap,
    );
  }
}

class _ThemeSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Tampilan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(value: ThemeMode.system, groupValue: current, onChanged: (v) { ref.read(themeProvider.notifier).state = v!; Navigator.pop(context); }, title: const Text('Ikut sistem')),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(value: ThemeMode.light, groupValue: current, onChanged: (v) { ref.read(themeProvider.notifier).state = v!; Navigator.pop(context); }, title: const Text('Terang')),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(value: ThemeMode.dark, groupValue: current, onChanged: (v) { ref.read(themeProvider.notifier).state = v!; Navigator.pop(context); }, title: const Text('Gelap')),
        ],
      ),
    );
  }
}
