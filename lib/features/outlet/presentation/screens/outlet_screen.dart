import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/outlet_provider.dart';
import '../../domain/outlet_model.dart';

class OutletScreen extends ConsumerWidget {
  const OutletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlets = ref.watch(outletProvider);
    final selectedOutlet = ref.watch(selectedOutletProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Kelola Outlet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        backgroundColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
        child: Icon(Icons.add, color: isDark ? AppColors.obsidian : Colors.white),
      ),
      body: outlets.isEmpty
          ? EmptyState(
              icon: Icons.store_outlined,
              title: 'Belum ada outlet',
              subtitle: 'Tambahkan outlet/cabang bisnis Anda.',
              actionLabel: 'Tambah Outlet',
              onAction: () => _showForm(context, ref),
            )
          : Column(
              children: [
                // Current outlet indicator
                if (selectedOutlet != null)
                  Container(
                    width: double.infinity,
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Outlet aktif: ${selectedOutlet.name}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: outlets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _OutletCard(
                      outlet: outlets[i],
                      isDark: isDark,
                      isSelected:
                          selectedOutlet?.id == outlets[i].id,
                      onSelect: () => ref
                          .read(selectedOutletProvider.notifier)
                          .state = outlets[i],
                      onEdit: () => _showForm(context, ref,
                          existing: outlets[i]),
                      onToggle: () => ref
                          .read(outletProvider.notifier)
                          .toggleActive(outlets[i].id),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {OutletModel? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final addressCtrl =
        TextEditingController(text: existing?.address ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Outlet' : 'Edit Outlet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Outlet *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP'),
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
              if (nameCtrl.text.isEmpty) return;
              if (existing == null) {
                ref.read(outletProvider.notifier).add(OutletModel(
                  businessId: 'biz-001',
                  name: nameCtrl.text,
                  address: addressCtrl.text.isEmpty
                      ? null
                      : addressCtrl.text,
                  phone: phoneCtrl.text.isEmpty
                      ? null
                      : phoneCtrl.text,
                ));
              } else {
                ref.read(outletProvider.notifier).update(
                      existing.id,
                      existing.copyWith(
                        name: nameCtrl.text,
                        address: addressCtrl.text.isEmpty
                            ? null
                            : addressCtrl.text,
                        phone: phoneCtrl.text.isEmpty
                            ? null
                            : phoneCtrl.text,
                      ),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _OutletCard extends StatelessWidget {
  final OutletModel outlet;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _OutletCard({
    required this.outlet,
    required this.isDark,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isSelected
        ? AppColors.success
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: border, width: isSelected ? 1.5 : 1),
      ),
      child: ListTile(
        onTap: onSelect,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.successLight
                : (isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.store_outlined,
            size: 20,
            color: isSelected ? AppColors.success : AppColors.ashGray,
          ),
        ),
        title: Text(
          outlet.name,
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
            if (outlet.address?.isNotEmpty == true)
              Text(outlet.address!, style: AppTextStyles.caption),
            const SizedBox(height: 2),
            StatusBadge(
              label: outlet.isActive ? 'Aktif' : 'Nonaktif',
              type: outlet.isActive ? BadgeType.success : BadgeType.neutral,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(outlet.isActive ? 'Nonaktifkan' : 'Aktifkan'),
            ),
          ],
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'toggle') onToggle();
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}
