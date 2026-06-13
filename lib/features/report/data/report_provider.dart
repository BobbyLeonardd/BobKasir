import '../../../core/network/dio_client.dart';
import 'report_export_service.dart';

int _asInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return num.tryParse(v)?.toInt() ?? 0;
  return 0;
}

class ReportCashierRow {
  final String name;
  final String role;
  final int transactions;
  final int sales;
  const ReportCashierRow({
    required this.name,
    required this.role,
    required this.transactions,
    required this.sales,
  });
}

/// Everything the report screen needs: the export-ready [ReportData] plus the
/// per-cashier breakdown (PRD §16.6).
class FullReport {
  final ReportData data;
  final List<ReportCashierRow> byCashier;
  const FullReport({required this.data, required this.byCashier});
}

class ReportApiService {
  static String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Resolve a [period] into a date range. `custom` requires from/to.
  static (DateTime, DateTime) rangeFor(String period, {DateTime? from, DateTime? to}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      'weekly' => (today.subtract(Duration(days: now.weekday - 1)), now),
      'monthly' => (DateTime(now.year, now.month, 1), now),
      'yearly' => (DateTime(now.year, 1, 1), now),
      'custom' => (from ?? today, to ?? now),
      _ => (today, now), // daily
    };
  }

  static String label(String period) => switch (period) {
        'weekly' => 'Mingguan',
        'monthly' => 'Bulanan',
        'yearly' => 'Tahunan',
        'custom' => 'Custom',
        _ => 'Harian',
      };

  static Future<FullReport> load(String period, {DateTime? from, DateTime? to}) async {
    final (start, end) = rangeFor(period, from: from, to: to);
    final dio = DioClient.instance.dio;

    // 1) Aggregated report (completed orders only).
    final reportRes = await dio.get('/reports/custom', queryParameters: {
      'date_from': _d(start),
      'date_to': _d(end),
    });
    final r = Map<String, dynamic>.from(reportRes.data['data'] ?? {});

    List<Map<String, dynamic>> mapList(Object? v) =>
        v is List ? v.whereType<Map>().map(Map<String, dynamic>.from).toList() : [];

    final topProducts = mapList(r['top_products'])
        .map((p) => ReportProductRow(
              productName: p['name'] as String? ?? '-',
              category: '',
              qty: _asInt(p['qty']),
              revenue: _asInt(p['revenue']),
            ))
        .toList();

    final byCashier = mapList(r['by_cashier'])
        .map((c) => ReportCashierRow(
              name: c['cashier_name'] as String? ?? '-',
              role: c['cashier_role'] as String? ?? '',
              transactions: _asInt(c['transactions']),
              sales: _asInt(c['sales']),
            ))
        .toList();

    // 2) Order list for the range (all statuses) — detail + refund/cancel counts.
    final orders = <ReportOrderRow>[];
    var refunds = 0;
    var cancels = 0;
    try {
      final ordersRes = await dio.get('/orders', queryParameters: {
        'date_from': _d(start),
        'date_to': _d(end),
        'per_page': 100,
      });
      final body = ordersRes.data['data'];
      final items = body is Map ? body['data'] : body;
      for (final o in (items is List ? items : const [])) {
        if (o is! Map) continue;
        final m = Map<String, dynamic>.from(o);
        final status = m['order_status'] as String? ?? '';
        if (status == 'refunded') refunds++;
        if (status == 'cancelled') cancels++;
        final payments = m['payments'];
        final method = payments is List && payments.isNotEmpty
            ? (payments.length > 1
                ? 'Split'
                : (Map<String, dynamic>.from(payments.first)['method'] as String? ?? '-'))
            : '-';
        orders.add(ReportOrderRow(
          orderNumber: m['order_number'] as String? ?? '-',
          date: DateTime.tryParse(m['ordered_at']?.toString() ?? '') ?? end,
          cashierName: m['cashier_name'] as String? ?? '-',
          paymentMethod: method,
          total: _asInt(m['grand_total']),
          status: status,
        ));
      }
    } catch (_) {
      // Orders list is supplementary; ignore if it fails.
    }

    return FullReport(
      data: ReportData(
        period: label(period),
        from: start,
        to: end,
        totalSales: _asInt(r['total_sales']),
        totalTransactions: _asInt(r['total_transactions']),
        totalRefunds: refunds,
        totalCancels: cancels,
        orders: orders,
        topProducts: topProducts,
      ),
      byCashier: byCashier,
    );
  }
}
