import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../data/kitchen_provider.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every second for waiting time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orders = ref.watch(activeKitchenOrdersProvider);
    final now = DateTime.now();

    final waiting = orders
        .where((o) => o.status == KitchenOrderStatus.waiting)
        .toList();
    final preparing = orders
        .where((o) => o.status == KitchenOrderStatus.preparing)
        .toList();
    final ready = orders
        .where((o) => o.status == KitchenOrderStatus.ready)
        .toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050506) : const Color(0xFF1A1B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              'Kitchen Display',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Text(
            DateHelper.formatDateTime(now),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(width: AppSpacing.md),
          if (ready.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(kitchenProvider.notifier).removeServed(),
              icon: const Icon(Icons.clear_all, color: Colors.white70, size: 18),
              label: Text('Hapus Selesai',
                  style: AppTextStyles.buttonSmall
                      .copyWith(color: Colors.white70)),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tidak ada pesanan',
                    style: AppTextStyles.h2
                        .copyWith(color: Colors.white54),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // ── Column: Menunggu ──
                _KDSColumn(
                  title: 'MENUNGGU',
                  titleColor: AppColors.warning,
                  count: waiting.length,
                  orders: waiting,
                  isDark: isDark,
                  onAction: (id) => ref
                      .read(kitchenProvider.notifier)
                      .updateStatus(id, KitchenOrderStatus.preparing),
                  actionLabel: 'PROSES',
                  actionColor: AppColors.info,
                ),
                _VerticalDivider(),

                // ── Column: Diproses ──
                _KDSColumn(
                  title: 'DIPROSES',
                  titleColor: AppColors.info,
                  count: preparing.length,
                  orders: preparing,
                  isDark: isDark,
                  onAction: (id) => ref
                      .read(kitchenProvider.notifier)
                      .updateStatus(id, KitchenOrderStatus.ready),
                  actionLabel: 'SIAP',
                  actionColor: AppColors.success,
                ),
                _VerticalDivider(),

                // ── Column: Siap ──
                _KDSColumn(
                  title: 'SIAP SAJI',
                  titleColor: AppColors.success,
                  count: ready.length,
                  orders: ready,
                  isDark: isDark,
                  onAction: (id) => ref
                      .read(kitchenProvider.notifier)
                      .updateStatus(id, KitchenOrderStatus.served),
                  actionLabel: 'DISAJIKAN',
                  actionColor: Colors.purple,
                ),
              ],
            ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: Colors.white12,
    );
  }
}

class _KDSColumn extends StatelessWidget {
  final String title;
  final Color titleColor;
  final int count;
  final List<KitchenOrder> orders;
  final bool isDark;
  final void Function(String) onAction;
  final String actionLabel;
  final Color actionColor;

  const _KDSColumn({
    required this.title,
    required this.titleColor,
    required this.count,
    required this.orders,
    required this.isDark,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: titleColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: titleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white12),

          // Order cards
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'Kosong',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _KDSCard(
                      order: orders[i],
                      onAction: () => onAction(orders[i].id),
                      actionLabel: actionLabel,
                      actionColor: actionColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KDSCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onAction;
  final String actionLabel;
  final Color actionColor;

  const _KDSCard({
    required this.order,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  String get _waitingLabel {
    final min = order.waitingTime.inMinutes;
    final sec = order.waitingTime.inSeconds % 60;
    if (min > 0) return '$min m $sec s';
    return '$sec s';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = order.isUrgent
        ? AppColors.danger.withValues(alpha: 0.15)
        : const Color(0xFF252629);
    final borderColor = order.isUrgent
        ? AppColors.danger.withValues(alpha: 0.5)
        : Colors.white12;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                if (order.tableNumber?.isNotEmpty == true) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Meja ${order.tableNumber}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Waiting time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.isUrgent
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _waitingLabel,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.isUrgent ? AppColors.danger : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (item.note?.isNotEmpty == true)
                            Text(
                              '📌 ${item.note}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          if (order.orderNote?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '📝 ${order.orderNote}',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    color: Colors.orange[300],
                  ),
                ),
              ),
            ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: GestureDetector(
              onTap: onAction,
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
