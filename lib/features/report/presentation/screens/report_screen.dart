import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/report_export_service.dart';
import '../../data/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _period = 'daily';
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;
  late Future<FullReport> _future;

  final _periods = [
    ('daily', 'Harian'),
    ('weekly', 'Mingguan'),
    ('monthly', 'Bulanan'),
    ('yearly', 'Tahunan'),
    ('custom', 'Custom'),
  ];

  @override
  void initState() {
    super.initState();
    _future = ReportApiService.load('daily');
  }

  void _selectPeriod(String period) {
    if (period == 'custom') {
      _pickCustomRange();
      return;
    }
    setState(() {
      _period = period;
      _future = ReportApiService.load(period);
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (range == null) return;
    setState(() {
      _period = 'custom';
      _future = ReportApiService.load('custom', from: range.start, to: range.end);
    });
  }

  Future<void> _exportPdf(ReportData data) async {
    setState(() => _isExportingPdf = true);
    try {
      final path = await ReportExportService.exportPdf(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('PDF berhasil dibuat'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => ReportExportService.openFile(path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportExcel(ReportData data) async {
    setState(() => _isExportingExcel = true);
    try {
      final path = await ReportExportService.exportExcel(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Excel berhasil dibuat'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () => ReportExportService.openFile(path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal export Excel: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Laporan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('PERIODE', isDark),
            const SizedBox(height: AppSpacing.sm),
            _periodSelector(isDark),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<FullReport>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (snap.hasError || !snap.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Gagal memuat laporan',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.ashGray,
                              )),
                          TextButton(
                            onPressed: () => _selectPeriod(_period),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _content(snap.data!, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(FullReport report, bool isDark) {
    final data = report.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('RINGKASAN', isDark),
        const SizedBox(height: AppSpacing.sm),
        _SummaryGrid(data: data, isDark: isDark),
        const SizedBox(height: AppSpacing.lg),

        _label('EXPORT', isDark),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Export PDF',
                onPressed: () => _exportPdf(data),
                isLoading: _isExportingPdf,
                prefixIcon: Icons.picture_as_pdf_outlined,
                isFullWidth: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Export Excel',
                onPressed: () => _exportExcel(data),
                isLoading: _isExportingExcel,
                variant: AppButtonVariant.secondary,
                prefixIcon: Icons.table_chart_outlined,
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        _label('PRODUK TERLARIS', isDark),
        const SizedBox(height: AppSpacing.sm),
        _TopProductsList(products: data.topProducts, isDark: isDark),
        const SizedBox(height: AppSpacing.lg),

        _label('PERFORMA KASIR', isDark),
        const SizedBox(height: AppSpacing.sm),
        _CashierList(rows: report.byCashier, isDark: isDark),
        const SizedBox(height: AppSpacing.lg),

        _label('TRANSAKSI', isDark),
        const SizedBox(height: AppSpacing.sm),
        _OrdersList(orders: data.orders, isDark: isDark),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
        ),
      );

  Widget _periodSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final isSelected = _period == p.$1;
          final accent = isDark ? AppColors.champagneGold : AppColors.charcoal;
          return GestureDetector(
            onTap: () => _selectPeriod(p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.1)
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                p.$2,
                style: AppTextStyles.buttonSmall.copyWith(
                  color: isSelected
                      ? accent
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.ashGray),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final ReportData data;
  final bool isDark;
  const _SummaryGrid({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Penjualan', CurrencyHelper.format(data.totalSales), AppColors.success, Icons.trending_up_outlined),
      ('Transaksi', '${data.totalTransactions}', AppColors.info, Icons.receipt_long_outlined),
      ('Refund', '${data.totalRefunds}', AppColors.danger, Icons.currency_exchange_outlined),
      ('Cancel', '${data.totalCancels}', AppColors.warning, Icons.cancel_outlined),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      children: items.map((item) {
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
              Icon(item.$4, size: 18, color: item.$3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(item.$1, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final List<ReportProductRow> products;
  final bool isDark;
  const _TopProductsList({required this.products, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    if (products.isEmpty) {
      return _emptyBox('Belum ada penjualan pada periode ini.', bg, border);
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: products.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
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
                        child: Text('#${i + 1}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.champagneGold
                                  : AppColors.brushedGold,
                            )),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.productName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              )),
                          Text('${p.qty} terjual', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(CurrencyHelper.format(p.revenue),
                        style: AppTextStyles.price.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        )),
                  ],
                ),
              ),
              if (i < products.length - 1) Divider(height: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CashierList extends StatelessWidget {
  final List<ReportCashierRow> rows;
  final bool isDark;
  const _CashierList({required this.rows, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    if (rows.isEmpty) {
      return _emptyBox('Belum ada aktivitas kasir.', bg, border);
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              )),
                          Text('${c.role} · ${c.transactions} transaksi',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(CurrencyHelper.format(c.sales),
                        style: AppTextStyles.price.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        )),
                  ],
                ),
              ),
              if (i < rows.length - 1) Divider(height: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<ReportOrderRow> orders;
  final bool isDark;
  const _OrdersList({required this.orders, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    if (orders.isEmpty) {
      return _emptyBox('Belum ada transaksi pada periode ini.', bg, border);
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: orders.asMap().entries.map((e) {
          final i = e.key;
          final o = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.orderNumber,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w500,
                              )),
                          Text('${o.cashierName} · ${o.paymentMethod}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyHelper.format(o.total),
                            style: AppTextStyles.price.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            )),
                        StatusBadge(
                          label: o.status,
                          type: o.status == 'completed'
                              ? BadgeType.success
                              : BadgeType.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < orders.length - 1) Divider(height: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Widget _emptyBox(String text, Color bg, Color border) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
