import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/api_client.dart';
import '../../widgets/app_button.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akun & Role')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah User'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiClient.parseError(e), style: const TextStyle(color: AppColors.error))),
        data: (users) => users.isEmpty
            ? const Center(child: Text('Belum ada user lain.', style: TextStyle(color: AppColors.onSurface2)))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s4),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = users[i];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Text(u.name.isNotEmpty ? u.name[0] : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.onSurface2)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(999)),
                          child: Text(u.roleLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'disable', child: Text('Nonaktifkan')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus',
                                    style: TextStyle(color: AppColors.error))),
                          ],
                          onSelected: (action) => _handleAction(context, ref, u, action),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, UserModel user, String action) async {
    final repo = ref.read(userRepositoryProvider);
    try {
      if (action == 'disable') {
        await repo.updateUser(user.id, status: 'inactive');
        ref.invalidate(usersProvider);
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus User?'),
            content: Text('Hapus ${user.name} dari sistem?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hapus', style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
        if (ok == true) {
          await repo.deleteUser(user.id);
          ref.invalidate(usersProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiClient.parseError(e))));
      }
    }
  }

  void _showAddUserSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddUserSheet(onCreated: () => ref.invalidate(usersProvider)),
    );
  }
}

class _AddUserSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _AddUserSheet({required this.onCreated});

  @override
  ConsumerState<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends ConsumerState<_AddUserSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  UserRole _role = UserRole.cashier;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(userRepositoryProvider).createUser(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            role: _role == UserRole.admin ? 'admin' : 'cashier',
          );
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s4),
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap')),
          const SizedBox(height: AppSpacing.s3),
          TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: AppSpacing.s3),
          DropdownButtonFormField<UserRole>(
            // ignore: deprecated_member_use
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [UserRole.admin, UserRole.cashier]
                .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r == UserRole.admin ? 'Admin' : 'Kasir')))
                .toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
              label: _loading ? 'Menyimpan...' : 'Tambah User',
              onPressed: _loading ? null : _submit),
        ],
      ),
    );
  }
}
