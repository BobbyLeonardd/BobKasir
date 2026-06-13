import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/order_service.dart';
import '../../domain/order_record.dart';

enum OrderStatus { completed, cancelRequested, cancelled, refundRequested, refunded, pendingSync, synced, failedSync }

extension OrderStatusExt on OrderStatus {
  String get label => switch (this) {
    OrderStatus.completed => 'Selesai',
    OrderStatus.cancelRequested => 'Req. Cancel',
    OrderStatus.cancelled => 'Dibatalkan',
    OrderStatus.refundRequested => 'Req. Refund',
    OrderStatus.refunded => 'Refunded',
    OrderStatus.pendingSync => 'Belum Sync',
    OrderStatus.synced => 'Tersinkron',
    OrderStatus.failedSync => 'Gagal Sync',
  };
  BadgeType get badgeType => switch (this) {
    OrderStatus.completed => BadgeType.success,
    OrderStatus.cancelRequested => BadgeType.warning,
    OrderStatus.cancelled => BadgeType.danger,
    OrderStatus.refundRequested => BadgeType.warning,
    OrderStatus.refunded => BadgeType.info,
    OrderStatus.pendingSync => BadgeType.warning,
    OrderStatus.synced => BadgeType.success,
    OrderStatus.failedSync => BadgeType.danger,
  };
}

/// Derive a single display status from order + sync status.
OrderStatus orderDisplayStatus(OrderRecord o) {
  if (o.orderStatus == 'cancelled') return OrderStatus.cancelled;
  return switch (o.syncStatus) {
    'synced' => OrderStatus.synced,
    'failed' => OrderStatus.failedSync,
    'pending' || 'syncing' => OrderStatus.pendingSync,
    _ => OrderStatus.completed,
  };
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderService.getRecentOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = OrderService.getRecentOrders());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<OrderRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal memuat pesanan',
              subtitle: '${snapshot.error}',
            );
          }
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan',
              subtitle: 'Pesanan yang sudah checkout akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.md,
              ),
              itemCount: orders.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _OrderCard(
                order: orders[i],
                isDark: isDark,
                onTap: () => context
                    .push('/orders/${orders[i].id}')
                    .then((_) => _refresh()),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord order;
  final bool isDark;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final status = orderDisplayStatus(order);
    final customerName = order.customerName ?? '';
    final tableNumber = order.tableNumber ?? '';

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
                Expanded(
                  child: Text(
                    order.orderNumber,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  label: status.label,
                  type: status.badgeType,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.access_time_outlined,
                    size: 13, color: AppColors.ashGray),
                const SizedBox(width: 4),
                Text(
                  DateHelper.formatDateTime(order.orderedAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (customerName.isNotEmpty) ...[
                  _Tag(
                    icon: Icons.person_outline,
                    label: customerName,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (tableNumber.isNotEmpty) ...[
                  _Tag(
                    icon: Icons.table_restaurant_outlined,
                    label: 'Meja $tableNumber',
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _Tag(
                  icon: Icons.badge_outlined,
                  label: order.cashierName,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.paymentMethod,
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  CurrencyHelper.format(order.grandTotal),
                  style: AppTextStyles.price.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 15,
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

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _Tag({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.ashGray),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
        )),
      ],
    );
  }
}
