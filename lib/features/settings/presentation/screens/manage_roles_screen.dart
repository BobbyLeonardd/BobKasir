import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state.dart';

class _TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;

  const _TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

final _dummyTeam = [
  const _TeamMember(
    id: '1',
    name: 'Sari Dewi',
    email: 'sari@bobkasir.id',
    role: 'Manager',
    status: 'active',
  ),
  const _TeamMember(
    id: '2',
    name: 'Budi Santoso',
    email: 'budi@bobkasir.id',
    role: 'Karyawan',
    status: 'active',
  ),
  const _TeamMember(
    id: '3',
    name: 'Ani Rahayu',
    email: 'ani@bobkasir.id',
    role: 'Karyawan',
    status: 'inactive',
  ),
];

class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Kelola Tim'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(context, isDark),
        backgroundColor:
            isDark ? AppColors.champagneGold : AppColors.charcoal,
        child: Icon(
          Icons.person_add_outlined,
          color: isDark ? AppColors.obsidian : Colors.white,
        ),
      ),
      body: _dummyTeam.isEmpty
          ? EmptyState(
              icon: Icons.group_outlined,
              title: 'Belum ada anggota tim',
              subtitle:
                  'Tambahkan manager atau karyawan untuk mulai beroperasi.',
              actionLabel: 'Tambah Anggota',
              onAction: () => _showAddMemberDialog(context, isDark),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.md,
              ),
              itemCount: _dummyTeam.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _MemberCard(
                member: _dummyTeam[i],
                isDark: isDark,
              ),
            ),
    );
  }

  void _showAddMemberDialog(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'Karyawan';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Anggota Tim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                      value: 'Manager', child: Text('Manager')),
                  DropdownMenuItem(
                      value: 'Karyawan', child: Text('Karyawan')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call API to create member
                Navigator.pop(ctx);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final _TeamMember member;
  final bool isDark;

  const _MemberCard({required this.member, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isActive = member.status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: isDark
              ? AppColors.champagneGold.withValues(alpha: 0.1)
              : AppColors.charcoal.withValues(alpha: 0.08),
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.champagneGold
                  : AppColors.charcoal,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Row(
              children: [
                StatusBadge(
                  label: member.role,
                  type: member.role == 'Manager'
                      ? BadgeType.info
                      : BadgeType.neutral,
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: isActive ? 'Aktif' : 'Nonaktif',
                  type: isActive ? BadgeType.success : BadgeType.danger,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem(
              value: isActive ? 'deactivate' : 'activate',
              child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
            ),
            const PopupMenuItem(
              value: 'reset_pw',
              child: Text('Reset Password'),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Text(
                'Hapus Akses',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
          onSelected: (v) {
            // TODO: Handle each action via API
          },
        ),
      ),
    );
  }
}
