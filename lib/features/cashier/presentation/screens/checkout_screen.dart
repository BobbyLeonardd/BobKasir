import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/cart_provider.dart';
import '../../domain/cart_item.dart';
import '../../domain/checkout_data.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _customerNameController = TextEditingController();
  final _tableController = TextEditingController();
  final _noteController = TextEditingController();

  // Totals
  final int _discountTransaction = 0;
  final double _taxRate = 0.0;      // e.g. 0.10 for 10%
  final double _serviceRate = 0.0;  // e.g. 0.05 for 5%

  int _grandTotal(int subtotal) {
    final afterDiscount = subtotal - _discountTransaction;
    final tax = (afterDiscount * _taxRate).round();
    final service = (afterDiscount * _serviceRate).round();
    return afterDiscount + tax + service;
  }

  CheckoutData _buildCheckoutData(int subtotal, int grand) {
    final afterDiscount = subtotal - _discountTransaction;
    String? trim(String s) => s.trim().isEmpty ? null : s.trim();
    return CheckoutData(
      customerName: trim(_customerNameController.text),
      tableNumber: trim(_tableController.text),
      note: trim(_noteController.text),
      subtotal: subtotal,
      discountTotal: _discountTransaction,
      taxTotal: (afterDiscount * _taxRate).round(),
      serviceChargeTotal: (afterDiscount * _serviceRate).round(),
      grandTotal: grand,
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _tableController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final grand = _grandTotal(subtotal);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order items
            _SectionTitle(label: 'ITEM PESANAN', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildOrderItems(cart, isDark),
            const SizedBox(height: AppSpacing.lg),

            // Customer data (optional)
            _SectionTitle(label: 'DATA CUSTOMER (OPSIONAL)', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Nama Customer',
              hint: 'Kosongkan jika tidak perlu',
              controller: _customerNameController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nomor Meja',
              hint: 'Misal: 5 atau A3',
              controller: _tableController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Catatan Pesanan',
              hint: 'Catatan untuk dapur',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary
            _SectionTitle(label: 'RINGKASAN', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildSummary(subtotal, grand, isDark),
            const SizedBox(height: AppSpacing.xl),

            // Proceed
            AppButton(
              label: 'Pilih Pembayaran',
              onPressed: () => context.push(
                AppRoutes.payment,
                extra: _buildCheckoutData(subtotal, grand),
              ),
              prefixIcon: Icons.payment_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(List<CartItem> cart, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: List.generate(cart.length, (i) {
          final item = cart[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.qty}',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (item.note.isNotEmpty)
                            Text(
                              item.note,
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyHelper.format(item.subtotal),
                      style: AppTextStyles.price.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < cart.length - 1)
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummary(int subtotal, int grand, bool isDark) {
    final taxAmount = (subtotal * _taxRate).round();
    final serviceAmount = (subtotal * _serviceRate).round();
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: CurrencyHelper.format(subtotal),
            isDark: isDark,
          ),
          if (_discountTransaction > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(
              label: 'Diskon',
              value: '- ${CurrencyHelper.format(_discountTransaction)}',
              isDark: isDark,
              valueColor: AppColors.danger,
            ),
          ],
          if (taxAmount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(
              label: 'Pajak (${(_taxRate * 100).toStringAsFixed(0)}%)',
              value: CurrencyHelper.format(taxAmount),
              isDark: isDark,
            ),
          ],
          if (serviceAmount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _SummaryRow(
              label: 'Service Charge (${(_serviceRate * 100).toStringAsFixed(0)}%)',
              value: CurrencyHelper.format(serviceAmount),
              isDark: isDark,
            ),
          ],
          Divider(height: AppSpacing.lg, color: border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                CurrencyHelper.format(grand),
                style: AppTextStyles.priceTotal.copyWith(
                  color: isDark
                      ? AppColors.champagneGold
                      : AppColors.brushedGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionTitle({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(
        color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.price.copyWith(
            color: valueColor ??
                (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
