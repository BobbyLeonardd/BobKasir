import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../data/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => _ErrorState(
          isDark: isDark,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageH,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label: 'RINGKASAN HARI INI', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _SummaryGrid(summary: summary, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                _SectionLabel(label: 'PRODUK TERLARIS', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _TopProducts(items: summary.topProducts, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                _SectionLabel(label: 'METODE PEMBAYARAN', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _PaymentBreakdown(
                  items: summary.paymentBreakdown,
                  total: summary.paymentTotal,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorState({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40,
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
          const SizedBox(height: AppSpacing.sm),
          Text('Gagal memuat dashboard',
              style: AppTextStyles.bodyMedium.copyWith(
                color:
                    isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
              )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

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

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;
  final bool isDark;
  const _SummaryGrid({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Total Penjualan',
        value: CurrencyHelper.format(summary.totalSales),
        icon: Icons.trending_up_outlined,
        color: AppColors.success,
      ),
      _SummaryItem(
        label: 'Total Transaksi',
        value: '${summary.totalTransactions}',
        icon: Icons.receipt_long_outlined,
        color: AppColors.info,
      ),
      _SummaryItem(
        label: 'Rata-rata Transaksi',
        value: CurrencyHelper.format(summary.avgTransaction),
        icon: Icons.bar_chart_outlined,
        color: AppColors.warning,
      ),
      _SummaryItem(
        label: 'Cancel / Refund',
        value: '${summary.totalCancels} / ${summary.totalRefunds}',
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children:
          items.map((item) => _SummaryCard(item: item, isDark: isDark)).toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  final bool isDark;
  const _SummaryCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, size: 20, color: item.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(item.label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  final List<TopProduct> items;
  final bool isDark;
  const _TopProducts({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: items.isEmpty ? const EdgeInsets.all(AppSpacing.md) : EdgeInsets.zero,
      child: items.isEmpty
          ? Text('Belum ada penjualan hari ini.', style: AppTextStyles.bodySmall)
          : Column(
              children: List.generate(items.length, (i) {
                final p = items[i];
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
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '#${i + 1}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.champagneGold
                                      : AppColors.brushedGold,
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
                                  p.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text('${p.qty} terjual',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyHelper.format(p.revenue),
                            style: AppTextStyles.price.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, color: border),
                  ],
                );
              }),
            ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final List<PaymentMethodStat> items;
  final int total;
  final bool isDark;
  const _PaymentBreakdown({
    required this.items,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bar = isDark ? AppColors.champagneGold : AppColors.charcoal;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: items.isEmpty
          ? Text('Belum ada pembayaran hari ini.',
              style: AppTextStyles.bodySmall)
          : Column(
              children: items.map((item) {
                final fraction = total > 0 ? item.total / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.method,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${(fraction * 100).toStringAsFixed(0)}% · ${CurrencyHelper.format(item.total)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation(bar),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
