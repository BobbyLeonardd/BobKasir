import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/models/order_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_button.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider).value ?? [];
    final user = ref.watch(currentUserProvider);
    if (orders.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final order = orders.firstWhere((o) => o.id.replaceAll('#', '') == orderId, orElse: () => orders.first);
    final fmt = DateFormat('dd MMM yyyy  HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Order ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              StatusChip.fromOrderStatus(order.status),
              const Spacer(),
              Text(fmt.format(order.createdAt), style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
            ]),
            const SizedBox(height: AppSpacing.s4),
            Text('Kasir: ${order.cashierName}', style: const TextStyle(color: AppColors.onSurface2)),
            if (order.customerName != null) Text('Customer: ${order.customerName}', style: const TextStyle(color: AppColors.onSurface2)),
            if (order.tableNumber != null) Text('Meja: ${order.tableNumber}', style: const TextStyle(color: AppColors.onSurface2)),
            const Divider(height: 24),
            const Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.s3),
            ...order.items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text('${i.productName} × ${i.qty}')),
                Text(formatRupiah(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(formatRupiah(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
            ]),
            if (order.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...order.payments.map((p) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Bayar (${p.method.label})', style: const TextStyle(color: AppColors.onSurface2)),
                Text(formatRupiah(p.amount), style: const TextStyle(color: AppColors.onSurface2)),
              ])),
              if (order.change > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Kembalian', style: TextStyle(color: AppColors.onSurface2)),
                Text(formatRupiah(order.change), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
              ]),
            ],
            const SizedBox(height: AppSpacing.s6),
            AppButton(label: 'Cetak Struk Customer', variant: AppButtonVariant.secondary, onPressed: () {}),
            const SizedBox(height: AppSpacing.s3),
            AppButton(label: 'Cetak Struk Dapur', variant: AppButtonVariant.secondary, onPressed: () {}),
            if (order.status == OrderStatus.requestCancel && user?.canCancelOrder == true) ...[
              const SizedBox(height: AppSpacing.s6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.pending_outlined, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Kasir mengajukan request cancel untuk order ini.', style: TextStyle(color: AppColors.warning, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: AppSpacing.s3),
              Row(children: [
                Expanded(
                  child: AppButton(
                    label: 'Setujui Cancel',
                    variant: AppButtonVariant.danger,
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Setujui Cancel?'),
                          content: const Text('Order akan dibatalkan.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Setujui', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        try {
                          await ref.read(orderRepositoryProvider).approveCancel(order.id);
                          ref.invalidate(ordersProvider);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: AppButton(
                    label: 'Tolak',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      try {
                        await ref.read(orderRepositoryProvider).rejectCancel(order.id);
                        ref.invalidate(ordersProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancel ditolak')));
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
                      }
                    },
                  ),
                ),
              ]),
            ] else if (order.status == OrderStatus.completed || order.status == OrderStatus.open) ...[
              const SizedBox(height: AppSpacing.s6),
              if (user?.canCancelOrder == true)
                AppButton(
                  label: 'Cancel Order',
                  variant: AppButtonVariant.danger,
                  onPressed: () => _showCancelDialog(context, ref, order, isRequest: false),
                ),
              if (user?.isCashier == true)
                AppButton(
                  label: 'Request Cancel',
                  variant: AppButtonVariant.danger,
                  onPressed: () => _showCancelDialog(context, ref, order, isRequest: true),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, OrderModel order, {required bool isRequest}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isRequest ? 'Request Cancel' : 'Cancel Order'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Alasan (wajib)', hintText: 'Tuliskan alasan...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              Navigator.pop(context);
              try {
                if (isRequest) {
                  await ref.read(orderRepositoryProvider).requestCancel(order.id, ctrl.text);
                } else {
                  await ref.read(orderRepositoryProvider).cancelOrder(order.id, ctrl.text);
                }
                ref.invalidate(ordersProvider);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
              }
            },
            child: Text(isRequest ? 'Kirim Request' : 'Cancel', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
