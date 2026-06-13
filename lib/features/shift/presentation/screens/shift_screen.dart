import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/storage/local_db.dart';
import '../../data/shift_provider.dart';
import '../../domain/shift_model.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftAsync = ref.watch(shiftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Kasir')),
      body: shiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (activeShift) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.pageV,
          ),
          child: Column(
            children: [
              if (activeShift != null) ...[
                _ActiveShiftCard(shift: activeShift, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Tutup Shift',
                  onPressed: () => context.push(AppRoutes.closeShift),
                  variant: AppButtonVariant.destructive,
                  prefixIcon: Icons.lock_clock_outlined,
                ),
              ] else ...[
                _NoShiftCard(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Buka Shift',
                  onPressed: () => context.push(AppRoutes.openShift),
                  prefixIcon: Icons.lock_open_outlined,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RIWAYAT SHIFT',
                  style: AppTextStyles.label.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.ashGray,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ShiftHistoryList(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final bool isDark;
  const _ActiveShiftCard({required this.shift, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Aktif',
                style: AppTextStyles.h3
                    .copyWith(color: AppColors.success),
              ),
              const StatusBadge(
                  label: 'Aktif', type: BadgeType.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Row('Dibuka',
              DateHelper.formatDateTime(shift.openedAt), isDark),
          _Row('Kasir',
              '${shift.userName} (${shift.userRole})', isDark),
          _Row('Modal Awal',
              CurrencyHelper.format(shift.openingCash), isDark),
          Divider(
            height: AppSpacing.lg,
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
          _Row('Total Transaksi',
              '${shift.totalTransactions}', isDark),
          _Row('Total Cash',
              CurrencyHelper.format(shift.totalCash), isDark),
          _Row('Total QRIS',
              CurrencyHelper.format(shift.totalQris), isDark),
          const SizedBox(height: AppSpacing.xs),
          _Row('Total Penjualan',
              CurrencyHelper.format(shift.totalSales), isDark,
              bold: true),
        ],
      ),
    );
  }
}

class _NoShiftCard extends StatelessWidget {
  final bool isDark;
  const _NoShiftCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.lock_clock_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.ashGray),
          const SizedBox(height: AppSpacing.md),
          Text('Belum ada shift aktif',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              )),
          const SizedBox(height: AppSpacing.xs),
          Text('Buka shift sebelum mulai transaksi',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool bold;

  const _Row(this.label, this.value, this.isDark, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: bold
                ? AppTextStyles.price.copyWith(
                    color: isDark
                        ? AppColors.champagneGold
                        : AppColors.brushedGold)
                : AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ShiftHistoryList extends ConsumerWidget {
  final bool isDark;
  const _ShiftHistoryList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LocalDb.instance.getShiftHistory(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final shifts = snap.data!
            .where((r) => r['status'] == 'closed')
            .toList();

        if (shifts.isEmpty) {
          return EmptyState(
            icon: Icons.history_outlined,
            title: 'Belum ada riwayat shift',
            subtitle: 'Riwayat shift yang sudah ditutup akan muncul di sini.',
          );
        }

        final bg =
            isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final border =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;

        return Column(
          children: shifts.map((row) {
            final shift = ShiftModel.fromDb(row);
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateHelper.formatDate(shift.openedAt),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${shift.userName} · ${DateHelper.formatTime(shift.openedAt)}'
                          '${shift.closedAt != null ? ' - ${DateHelper.formatTime(shift.closedAt!)}' : ''}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyHelper.format(shift.totalSales),
                    style: AppTextStyles.price.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
