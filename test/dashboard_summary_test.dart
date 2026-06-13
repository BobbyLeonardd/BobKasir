import 'package:flutter_test/flutter_test.dart';
import 'package:bobkasir/features/dashboard/data/dashboard_provider.dart';

/// SUM/AVG from the API can arrive as numbers or numeric strings depending on
/// the driver, so the parser must tolerate both.
void main() {
  test('parses summary with numeric values', () {
    final s = DashboardSummary.fromJson({
      'total_sales': 1250000,
      'total_transactions': 23,
      'avg_transaction': 54348,
      'total_refunds': 1,
      'total_cancels': 2,
      'top_products': [
        {'name': 'Latte', 'qty': 42, 'revenue': 1344000},
      ],
      'payment_breakdown': [
        {'method': 'cash', 'total': 800000, 'count': 15},
        {'method': 'qris', 'total': 450000, 'count': 8},
      ],
    });

    expect(s.totalSales, 1250000);
    expect(s.totalTransactions, 23);
    expect(s.topProducts, hasLength(1));
    expect(s.topProducts.first.name, 'Latte');
    expect(s.topProducts.first.qty, 42);
    expect(s.paymentBreakdown, hasLength(2));
    expect(s.paymentTotal, 1250000);
  });

  test('tolerates string numeric values from SUM()', () {
    final s = DashboardSummary.fromJson({
      'total_sales': '500000',
      'total_transactions': '10',
      'avg_transaction': '50000',
      'top_products': [
        {'name': 'Kopi', 'qty': '5', 'revenue': '75000'},
      ],
    });

    expect(s.totalSales, 500000);
    expect(s.totalTransactions, 10);
    expect(s.topProducts.first.qty, 5);
    expect(s.topProducts.first.revenue, 75000);
  });

  test('defaults to zero/empty on an empty payload', () {
    final s = DashboardSummary.fromJson({});
    expect(s.totalSales, 0);
    expect(s.topProducts, isEmpty);
    expect(s.paymentBreakdown, isEmpty);
    expect(s.paymentTotal, 0);
  });
}
