import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/open_bill_provider.dart';
import '../../domain/open_bill_model.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../auth/domain/user_model.dart';

class OpenBillScreen extends ConsumerWidget {
  const OpenBillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = ref.watch(activeBillsProvider);
    final role = ref.watch(currentRoleProvider) ?? UserRole.karyawan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Open Bill'),
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Baru'),
          ),
        ],
      ),
      body: bills.isEmpty
          ? EmptyState(
              icon: Icons.receipt_outlined,
              title: 'Belum ada open bill',
              subtitle: 'Buat open bill untuk menyimpan pesanan yang belum dibayar.',
              actionLabel: 'Buat Open Bill',
              onAction: () => _showCreateDialog(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.md,
              ),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _BillCard(
                bill: bills[i],
                isDark: isDark,
                role: role,
                onTap: () => _openBill(context, ref, bills[i]),
              ),
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final customerCtrl = TextEditingController();
    final tableCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Open Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Customer (Opsional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: tableCtrl,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja (Opsional)',
              ),
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
              ref.read(openBillProvider.notifier).createBill(
                    customerName: customerCtrl.text.isEmpty ? null : customerCtrl.text,
                    tableNumber: tableCtrl.text.isEmpty ? null : tableCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _openBill(BuildContext context, WidgetRef ref, OpenBillModel bill) {
    context.push('/open-bill/${bill.id}');
  }
}

class _BillCard extends StatelessWidget {
  final OpenBillModel bill;
  final bool isDark;
  final UserRole role;
  final VoidCallback onTap;

  const _BillCard({
    required this.bill,
    required this.isDark,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final badgeType = bill.status == OpenBillStatus.open
        ? BadgeType.success
        : bill.status == OpenBillStatus.updated
            ? BadgeType.warning
            : BadgeType.neutral;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bill.billNumber,
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 14,
                    )),
                StatusBadge(label: bill.status.label, type: badgeType),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (bill.customerName != null && bill.customerName!.isNotEmpty) ...[
                  Icon(Icons.person_outline, size: 13, color: AppColors.ashGray),
                  const SizedBox(width: 3),
                  Text(bill.customerName!, style: AppTextStyles.caption),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) ...[
                  Icon(Icons.table_restaurant_outlined, size: 13, color: AppColors.ashGray),
                  const SizedBox(width: 3),
                  Text('Meja ${bill.tableNumber!}', style: AppTextStyles.caption),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${bill.itemCount} item · ${DateHelper.formatTime(bill.updatedAt)}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  CurrencyHelper.format(bill.subtotal),
                  style: AppTextStyles.price.copyWith(
                    color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
