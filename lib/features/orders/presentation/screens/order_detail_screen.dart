import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../features/auth/data/auth_provider.dart';
import '../../../../features/auth/domain/user_model.dart';
import '../../../../features/printer/data/bluetooth_printer_service.dart';
import '../../data/order_service.dart';
import '../../domain/order_record.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Future<OrderRecord?> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderService.getOrderById(widget.orderId);
  }

  void _reload() {
    setState(() => _future = OrderService.getOrderById(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(currentRoleProvider) ?? UserRole.karyawan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Pesanan'),
      ),
      body: FutureBuilder<OrderRecord?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Pesanan tidak ditemukan',
              subtitle: 'Data pesanan ini tidak tersedia di perangkat.',
            );
          }
          return _buildContent(context, order, role, isDark);
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, OrderRecord order, UserRole role, bool isDark) {
    final status = orderDisplayStatus(order);
    final isCancelled = order.orderStatus == 'cancelled';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.pageV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(order.orderNumber,
                    overflow: TextOverflow.ellipsis, style: AppTextStyles.h2),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(label: status.label, type: status.badgeType),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _InfoCard(order: order, isDark: isDark),
          const SizedBox(height: AppSpacing.md),
          _ItemsCard(order: order, isDark: isDark),
          const SizedBox(height: AppSpacing.md),
          _PaymentCard(order: order, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          // Reprint — semua role (PRD §16.3)
          AppButton(
            label: 'Cetak Struk Customer',
            onPressed: () => _printCustomer(context, order),
            prefixIcon: Icons.print_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cetak Struk Dapur',
            onPressed: () => _printKitchen(context, order),
            variant: AppButtonVariant.ghost,
            prefixIcon: Icons.restaurant_outlined,
          ),
          const SizedBox(height: AppSpacing.md),

          // Cancel actions (hanya jika belum dibatalkan)
          if (!isCancelled) ...[
            if (role.canCancelDirect)
              AppButton(
                label: 'Cancel Order',
                onPressed: () => _showCancelDialog(context, order,
                    isRequest: false),
                variant: AppButtonVariant.destructive,
                prefixIcon: Icons.cancel_outlined,
              )
            else
              AppButton(
                label: 'Request Cancel',
                onPressed: () => _showCancelDialog(context, order,
                    isRequest: true),
                variant: AppButtonVariant.destructive,
                prefixIcon: Icons.cancel_outlined,
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: role.canApproveCancelRefund
                  ? 'Proses Refund'
                  : 'Request Refund',
              onPressed: () => _showRefundDialog(context, role),
              variant: AppButtonVariant.ghost,
              prefixIcon: Icons.currency_exchange_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  // ── Printing ──────────────────────────────
  void _printCustomer(BuildContext context, OrderRecord order) {
    final printer = ref.read(bluetoothPrinterProvider.notifier);
    if (!ref.read(isPrinterConnectedProvider)) {
      _notConnected(context);
      return;
    }
    printer.printCustomerReceipt(
      businessName: AppStorage.instance.businessName ?? 'BobKasir',
      address: '',
      phone: '',
      orderNumber: order.orderNumber,
      orderedAt: order.orderedAt,
      cashierName: order.cashierName,
      items: order.itemMaps,
      subtotal: order.subtotal,
      discountTotal: order.discountTotal,
      taxTotal: order.taxTotal,
      serviceTotal: order.serviceChargeTotal,
      grandTotal: order.grandTotal,
      paidAmount: order.paidAmount,
      changeAmount: order.changeAmount,
      paymentMethod: order.paymentMethod,
      customerName: order.customerName,
      tableNumber: order.tableNumber,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Struk customer dikirim ke printer')),
    );
  }

  void _printKitchen(BuildContext context, OrderRecord order) {
    final printer = ref.read(bluetoothPrinterProvider.notifier);
    if (!ref.read(isPrinterConnectedProvider)) {
      _notConnected(context);
      return;
    }
    printer.printKitchenReceipt(
      orderNumber: order.orderNumber,
      orderedAt: order.orderedAt,
      cashierName: order.cashierName,
      items: order.itemMaps,
      tableNumber: order.tableNumber,
      customerName: order.customerName,
      note: order.note,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Struk dapur dikirim ke printer')),
    );
  }

  void _notConnected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Printer belum terhubung. Hubungkan di Pengaturan > Printer.'),
      ),
    );
  }

  // ── Cancel ────────────────────────────────
  void _showCancelDialog(BuildContext context, OrderRecord order,
      {required bool isRequest}) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRequest ? 'Request Cancel Order' : 'Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRequest
                  ? 'Request ini akan dikirim ke Owner/Manager untuk disetujui.'
                  : 'Order akan langsung dibatalkan.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Align(
                alignment: Alignment.centerLeft, child: Text('Alasan:')),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Masukkan alasan...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              if (isRequest) {
                // Butuh backend untuk approval flow + notifikasi (PRD §16.5)
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request cancel terkirim')),
                );
              } else {
                await OrderService.cancelOrder(order.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order dibatalkan')),
                );
                _reload();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(isRequest ? 'Kirim Request' : 'Ya, Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Refund (butuh backend) ────────────────
  void _showRefundDialog(BuildContext context, UserRole role) {
    final reasonController = TextEditingController();
    String refundType = 'full';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
              role.canApproveCancelRefund ? 'Proses Refund' : 'Request Refund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: refundType,
                onChanged: (v) {
                  if (v != null) setState(() => refundType = v);
                },
                child: const Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Full'),
                        value: 'full',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Partial'),
                        value: 'partial',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Alasan refund'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(role.canApproveCancelRefund
                        ? 'Refund diproses'
                        : 'Request refund terkirim'),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.warning),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OrderRecord order;
  final bool isDark;
  const _InfoCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cashier = order.cashierRole.isEmpty
        ? order.cashierName
        : '${order.cashierName} (${order.cashierRole})';
    final rows = <(String, String)>[
      ('Tanggal', DateHelper.formatDateTime(order.orderedAt)),
      ('Kasir', cashier),
      if ((order.customerName ?? '').isNotEmpty)
        ('Customer', order.customerName!),
      if ((order.tableNumber ?? '').isNotEmpty)
        ('Nomor Meja', 'Meja ${order.tableNumber}'),
      if ((order.note ?? '').isNotEmpty) ('Catatan', order.note!),
    ];
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.$1, style: AppTextStyles.bodySmall),
              Flexible(
                child: Text(r.$2,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final OrderRecord order;
  final bool isDark;
  const _ItemsCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('ITEM', style: AppTextStyles.label.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
            )),
          ),
          Divider(height: 1, color: border),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text('${item.qty}×', style: AppTextStyles.bodySmall),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item.productName, style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ))),
                Text(CurrencyHelper.format(item.subtotal),
                    style: AppTextStyles.price.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final OrderRecord order;
  final bool isDark;
  const _PaymentCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _Row('Subtotal', CurrencyHelper.format(order.subtotal), isDark),
          if (order.discountTotal > 0)
            _Row('Diskon', '- ${CurrencyHelper.format(order.discountTotal)}',
                isDark),
          if (order.taxTotal > 0)
            _Row('Pajak', CurrencyHelper.format(order.taxTotal), isDark),
          if (order.serviceChargeTotal > 0)
            _Row('Service', CurrencyHelper.format(order.serviceChargeTotal),
                isDark),
          Divider(height: AppSpacing.md, color: border),
          _Row('TOTAL', CurrencyHelper.format(order.grandTotal), isDark,
              bold: true),
          ...order.payments.map((p) =>
              _Row(p.method, CurrencyHelper.format(p.amount), isDark)),
          if (order.changeAmount > 0)
            _Row('Kembalian', CurrencyHelper.format(order.changeAmount), isDark),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: bold
            ? AppTextStyles.price.copyWith(
                color: isDark ? AppColors.champagneGold : AppColors.brushedGold, fontSize: 16)
            : AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      ],
    );
  }
}
