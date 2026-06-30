import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/api_client.dart';
import '../../widgets/app_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(userRepositoryProvider).updateProfile(name: name);
      ref.read(currentUserProvider.notifier).state = updated;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await ref.read(userRepositoryProvider).deleteProfile();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              child: Text(user?.name.isNotEmpty == true ? user!.name[0] : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(999)),
              child: Text(user?.roleLabel ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: AppSpacing.s6),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: AppSpacing.s4),
            // Email read-only — perubahan email via endpoint terpisah
            TextField(
              controller: _emailCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Hubungi admin untuk mengubah email',
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: _saving ? 'Menyimpan...' : 'Simpan Perubahan',
              onPressed: _saving ? null : _saveProfile,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Ganti Sandi',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/forgot-password'),
            ),
            const SizedBox(height: AppSpacing.s8),
            const Divider(),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Hapus Akun',
              variant: AppButtonVariant.danger,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus Akun?'),
                  content: const Text('Semua data tenant akan dihapus. Tindakan ini tidak bisa dibatalkan setelah 30 hari.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    TextButton(
                      onPressed: () { Navigator.pop(context); _deleteAccount(); },
                      child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
