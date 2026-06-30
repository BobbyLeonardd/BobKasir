import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_client.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _rangeIndex = 0;
  final _ranges = ['Hari', 'Minggu', 'Bulan', 'Tahun'];
  final _periodKeys = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  Widget build(BuildContext context) {
    final period = _periodKeys[_rangeIndex];
    final chartAsync = ref.watch(chartDataProvider(period));
    final dailyAsync = ref.watch(dailyReportProvider);
    final compareAsync = ref.watch(compareReportProvider);
    final cashierAsync = ref.watch(cashierActivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              PopupMenuItem(value: 'excel', child: Text('Export Excel')),
            ],
            onSelected: (_) {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyReportProvider);
          ref.invalidate(compareReportProvider);
          ref.invalidate(cashierActivityProvider);
          ref.invalidate(chartDataProvider(period));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards from daily report
              dailyAsync.when(
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorBanner(ApiClient.parseError(e)),
                data: (data) {
                  final summary = data['data'] as Map<String, dynamic>? ?? {};
                  final revenue = (summary['total_revenue'] as num?)?.toDouble() ?? 0;
                  final txCount = (summary['transaction_count'] as num?)?.toInt() ?? 0;
                  final itemsSold = (summary['items_sold'] as num?)?.toInt() ?? 0;
                  final avgOrder = txCount > 0 ? revenue / txCount : 0.0;
                  final revChange = summary['revenue_change']?.toString() ?? '0';
                  final txChange = summary['transaction_change']?.toString() ?? '0';
                  return Column(children: [
                    Row(children: [
                      Expanded(child: _SummaryCard(label: 'Omzet Hari Ini', value: formatRupiahCompact(revenue), change: '$revChange%', up: !revChange.startsWith('-'))),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(child: _SummaryCard(label: 'Transaksi', value: '$txCount', change: txChange, up: !txChange.startsWith('-'))),
                    ]),
                    const SizedBox(height: AppSpacing.s4),
                    Row(children: [
                      Expanded(child: _SummaryCard(label: 'Produk Terjual', value: '$itemsSold', change: '', up: true)),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(child: _SummaryCard(label: 'Rata-rata Order', value: formatRupiahCompact(avgOrder), change: '', up: true)),
                    ]),
                  ]);
                },
              ),
              const SizedBox(height: AppSpacing.s6),
              const Text('Grafik Omzet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: AppSpacing.s3),
              Row(children: _ranges.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _rangeIndex == e.key,
                  onSelected: (_) => setState(() => _rangeIndex = e.key),
                ),
              )).toList()),
              const SizedBox(height: AppSpacing.s4),
              chartAsync.when(
                loading: () => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                error: (e, _) => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  alignment: Alignment.center,
                  child: Text(ApiClient.parseError(e), style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
                ),
                data: (chartData) {
                  final points = chartData['data'] as List? ?? [];
                  final labels = points.map((p) => (p['label'] ?? '').toString()).toList();
                  final values = points.map((p) => (p['value'] as num?)?.toDouble() ?? 0.0).toList();
                  final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.surface3),
                    ),
                    child: values.isEmpty
                        ? const Center(child: Text('Tidak ada data', style: TextStyle(color: AppColors.onSurface2, fontSize: 13)))
                        : _Barchart(values: values, labels: labels, maxVal: maxVal),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s6),
              const Text('Komparasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: AppSpacing.s3),
              compareAsync.when(
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _ErrorBanner(ApiClient.parseError(e)),
                data: (data) {
                  final compare = data['data'] as Map<String, dynamic>? ?? {};
                  return Column(children: [
                    if (compare['daily'] != null)
                      _CompareRow(
                        label: 'Hari ini vs kemarin',
                        current: (compare['daily']['current'] as num?)?.toDouble() ?? 0,
                        previous: (compare['daily']['previous'] as num?)?.toDouble() ?? 0,
                      ),
                    if (compare['weekly'] != null)
                      _CompareRow(
                        label: 'Minggu ini vs lalu',
                        current: (compare['weekly']['current'] as num?)?.toDouble() ?? 0,
                        previous: (compare['weekly']['previous'] as num?)?.toDouble() ?? 0,
                      ),
                    if (compare['monthly'] != null)
                      _CompareRow(
                        label: 'Bulan ini vs lalu',
                        current: (compare['monthly']['current'] as num?)?.toDouble() ?? 0,
                        previous: (compare['monthly']['previous'] as num?)?.toDouble() ?? 0,
                      ),
                  ]);
                },
              ),
              const SizedBox(height: AppSpacing.s6),
              const Text('Kasir Aktif Hari Ini', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: AppSpacing.s3),
              cashierAsync.when(
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _ErrorBanner(ApiClient.parseError(e)),
                data: (data) {
                  final cashiers = data['data'] as List? ?? [];
                  if (cashiers.isEmpty) {
                    return const Text('Tidak ada aktivitas kasir hari ini.',
                        style: TextStyle(color: AppColors.onSurface2, fontSize: 13));
                  }
                  return Column(
                    children: cashiers.map((c) => _CashierRow(
                      name: c['name']?.toString() ?? '',
                      txCount: (c['transaction_count'] as num?)?.toInt() ?? 0,
                      revenue: (c['total_revenue'] as num?)?.toDouble() ?? 0,
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool up;
  const _SummaryCard({required this.label, required this.value, required this.change, required this.up});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurface2, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          if (change.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14, color: up ? AppColors.success : AppColors.error),
              Text(change,
                  style: TextStyle(
                      fontSize: 12,
                      color: up ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Barchart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  const _Barchart({required this.values, required this.labels, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                formatRupiahCompact(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[i], style: const TextStyle(fontSize: 10, color: AppColors.onSurface3)),
                  );
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.surface3, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: i == values.length - 1 ? AppColors.primary : AppColors.primaryLight,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final double current;
  final double previous;
  const _CompareRow({required this.label, required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final pct = previous > 0 ? ((current - previous) / previous * 100).toStringAsFixed(1) : '0.0';
    final up = current >= previous;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.onSurface2, fontSize: 13))),
        Text('${formatRupiahCompact(current)} vs ${formatRupiahCompact(previous)}',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14, color: up ? AppColors.success : AppColors.error),
        Text('$pct%',
            style: TextStyle(
                fontSize: 12,
                color: up ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CashierRow extends StatelessWidget {
  final String name;
  final int txCount;
  final double revenue;
  const _CashierRow({required this.name, required this.txCount, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text('$txCount transaksi', style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
        const SizedBox(width: 8),
        Text(formatRupiahCompact(revenue), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}
