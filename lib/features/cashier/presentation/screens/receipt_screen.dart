import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../features/printer/data/bluetooth_printer_service.dart';

/// Data model passed from payment screen to receipt screen
class ReceiptData {
  final String orderNumber;
  final DateTime orderedAt;
  final String cashierName;
  final String? customerName;
  final String? tableNumber;
  final String? note;
  final List<Map<String, dynamic>> items; // {name, qty, price, subtotal, note}
  final int subtotal;
  final int discountTotal;
  final int taxTotal;
  final int serviceTotal;
  final int grandTotal;
  final int paidAmount;
  final int changeAmount;
  final String paymentMethod;

  const ReceiptData({
    required this.orderNumber,
    required this.orderedAt,
    required this.cashierName,
    this.customerName,
    this.tableNumber,
    this.note,
    required this.items,
    required this.subtotal,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.serviceTotal = 0,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
  });
}

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final extra = GoRouterState.of(context).extra;
    final data = extra is ReceiptData ? extra : _dummyReceipt();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Struk'),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.cashier),
            child: Text(
              'Transaksi Baru',
              style: AppTextStyles.button.copyWith(
                color: isDark
                    ? AppColors.champagneGold
                    : AppColors.brushedGold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              color: AppColors.successLight,
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 56),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pembayaran Berhasil',
                    style: AppTextStyles.h2
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.pageV,
              ),
              child: _ReceiptCard(data: data, isDark: isDark),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH, 0,
                AppSpacing.pageH, AppSpacing.pageV,
              ),
              child: Column(
                children: [
                  AppButton(
                    label: 'Cetak Struk Customer',
                    onPressed: () => _printCustomer(context, ref, data),
                    prefixIcon: Icons.print_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Cetak Struk Dapur',
                    onPressed: () => _printKitchen(context, ref, data),
                    variant: AppButtonVariant.ghost,
                    prefixIcon: Icons.restaurant_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Transaksi Baru',
                    onPressed: () => context.go(AppRoutes.cashier),
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printCustomer(BuildContext context, WidgetRef ref, ReceiptData data) {
    final printer = ref.read(bluetoothPrinterProvider.notifier);
    if (!ref.read(isPrinterConnectedProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Printer belum terhubung. Hubungkan printer di Pengaturan > Printer.'),
        ),
      );
      return;
    }
    printer.printCustomerReceipt(
      businessName: AppStorage.instance.businessName ?? 'BobKasir',
      address: '',
      phone: '',
      orderNumber: data.orderNumber,
      orderedAt: data.orderedAt,
      cashierName: data.cashierName,
      items: data.items,
      subtotal: data.subtotal,
      discountTotal: data.discountTotal,
      taxTotal: data.taxTotal,
      serviceTotal: data.serviceTotal,
      grandTotal: data.grandTotal,
      paidAmount: data.paidAmount,
      changeAmount: data.changeAmount,
      paymentMethod: data.paymentMethod,
      customerName: data.customerName,
      tableNumber: data.tableNumber,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Struk customer dikirim ke printer')),
    );
  }

  void _printKitchen(BuildContext context, WidgetRef ref, ReceiptData data) {
    final printer = ref.read(bluetoothPrinterProvider.notifier);
    if (!ref.read(isPrinterConnectedProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer belum terhubung.'),
        ),
      );
      return;
    }
    printer.printKitchenReceipt(
      orderNumber: data.orderNumber,
      orderedAt: data.orderedAt,
      cashierName: data.cashierName,
      items: data.items,
      tableNumber: data.tableNumber,
      customerName: data.customerName,
      note: data.note,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Struk dapur dikirim ke printer')),
    );
  }

  ReceiptData _dummyReceipt() => ReceiptData(
        orderNumber: 'BK-20260610-0001',
        orderedAt: DateTime.now(),
        cashierName: 'Admin',
        items: const [
          {'name': 'Americano', 'qty': 2, 'price': 25000, 'subtotal': 50000, 'note': ''},
          {'name': 'Latte', 'qty': 1, 'price': 32000, 'subtotal': 32000, 'note': ''},
        ],
        subtotal: 82000,
        grandTotal: 82000,
        paidAmount: 100000,
        changeAmount: 18000,
        paymentMethod: 'Cash',
      );
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptData data;
  final bool isDark;

  const _ReceiptCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('BobKasir', style: AppTextStyles.h2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                )),
              ],
            ),
          ),
          _Divider(isDark: isDark),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: [
                _InfoRow(label: 'No. Order', value: data.orderNumber, isDark: isDark),
                _InfoRow(label: 'Tanggal', value: DateHelper.receiptDate(data.orderedAt), isDark: isDark),
                _InfoRow(label: 'Kasir', value: data.cashierName, isDark: isDark),
                if (data.customerName != null && data.customerName!.isNotEmpty)
                  _InfoRow(label: 'Customer', value: data.customerName!, isDark: isDark),
                if (data.tableNumber != null && data.tableNumber!.isNotEmpty)
                  _InfoRow(label: 'Meja', value: data.tableNumber!, isDark: isDark),
              ],
            ),
          ),
          _Divider(isDark: isDark, dashed: true),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: data.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${item['qty']}×', style: AppTextStyles.bodySmall),
                    ),
                    Expanded(
                      child: Text(item['name'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          )),
                    ),
                    Text(
                      CurrencyHelper.format(item['subtotal'] as int),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          _Divider(isDark: isDark, dashed: true),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _InfoRow(label: 'Subtotal',
                    value: CurrencyHelper.format(data.subtotal), isDark: isDark),
                if (data.discountTotal > 0)
                  _InfoRow(label: 'Diskon',
                      value: '- ${CurrencyHelper.format(data.discountTotal)}',
                      isDark: isDark),
                if (data.taxTotal > 0)
                  _InfoRow(label: 'Pajak',
                      value: CurrencyHelper.format(data.taxTotal), isDark: isDark),
                if (data.serviceTotal > 0)
                  _InfoRow(label: 'Service',
                      value: CurrencyHelper.format(data.serviceTotal), isDark: isDark),
                Divider(height: AppSpacing.md, color: border),
                _InfoRow(label: 'TOTAL',
                    value: CurrencyHelper.format(data.grandTotal),
                    isDark: isDark, bold: true),
                _InfoRow(label: data.paymentMethod,
                    value: CurrencyHelper.format(data.paidAmount), isDark: isDark),
                if (data.changeAmount > 0)
                  _InfoRow(label: 'Kembalian',
                      value: CurrencyHelper.format(data.changeAmount), isDark: isDark),
              ],
            ),
          ),
          _Divider(isDark: isDark),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text('Terima kasih sudah berkunjung!',
                    style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('Created by ${AppConstants.companyName}',
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  final bool dashed;
  const _Divider({required this.isDark, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    if (!dashed) return Divider(height: 1, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(40, (i) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: i.isEven ? color : Colors.transparent,
          ),
        )),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.price.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray)),
        Text(value, style: style),
      ],
    );
  }
}
