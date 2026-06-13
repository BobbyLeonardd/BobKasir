import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/shift_provider.dart';

class CloseShiftScreen extends ConsumerStatefulWidget {
  const CloseShiftScreen({super.key});

  @override
  ConsumerState<CloseShiftScreen> createState() =>
      _CloseShiftScreenState();
}

class _CloseShiftScreenState extends ConsumerState<CloseShiftScreen> {
  final _actualCashController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  int get _actualCash =>
      int.tryParse(_actualCashController.text) ?? 0;

  @override
  void dispose() {
    _actualCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(shiftProvider.notifier).closeShift(
            actualCash: _actualCash,
            note: _noteController.text.isEmpty
                ? null
                : _noteController.text,
          );
      if (mounted) {
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tutup shift: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shift = ref.watch(activeShiftProvider);
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (shift == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tutup Shift')),
        body: const Center(child: Text('Tidak ada shift aktif')),
      );
    }

    final selisih = _actualCash - shift.expectedCash;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tutup Shift'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Text('RINGKASAN SHIFT',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                )),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _SummaryRow('Modal Awal',
                      CurrencyHelper.format(shift.openingCash),
                      isDark),
                  _SummaryRow('Total Cash',
                      CurrencyHelper.format(shift.totalCash), isDark),
                  _SummaryRow('Total QRIS',
                      CurrencyHelper.format(shift.totalQris), isDark),
                  _SummaryRow('Total Transfer',
                      CurrencyHelper.format(shift.totalTransfer),
                      isDark),
                  _SummaryRow('Total Debit',
                      CurrencyHelper.format(shift.totalDebit), isDark),
                  _SummaryRow('Total E-Wallet',
                      CurrencyHelper.format(shift.totalEwallet),
                      isDark),
                  Divider(height: AppSpacing.lg, color: border),
                  _SummaryRow(
                      'Total Penjualan',
                      CurrencyHelper.format(shift.totalSales),
                      isDark,
                      bold: true),
                  _SummaryRow(
                      'Uang Kas Seharusnya',
                      CurrencyHelper.format(shift.expectedCash),
                      isDark,
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            AppTextField(
              label: 'Uang Fisik Dihitung',
              hint: '0',
              controller: _actualCashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),

            if (_actualCash > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: selisih >= 0
                      ? AppColors.successLight
                      : AppColors.dangerLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selisih >= 0 ? 'Lebih Kas' : 'Kurang Kas',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: selisih >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    Text(
                      CurrencyHelper.format(selisih.abs()),
                      style: AppTextStyles.priceTotal.copyWith(
                        color: selisih >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Catatan Tutup Shift (Opsional)',
              controller: _noteController,
              maxLines: 2,
            ),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Tutup Shift & Cetak Laporan',
              onPressed: _close,
              isLoading: _isSaving,
              prefixIcon: Icons.print_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Tutup Shift Tanpa Cetak',
              onPressed: _close,
              variant: AppButtonVariant.ghost,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool bold;

  const _SummaryRow(this.label, this.value, this.isDark,
      {this.bold = false});

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
                        : AppColors.lightTextPrimary),
          ),
        ],
      ),
    );
  }
}
