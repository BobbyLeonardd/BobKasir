import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

int _asInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return num.tryParse(v)?.toInt() ?? 0;
  return 0;
}

class TopProduct {
  final String name;
  final int qty;
  final int revenue;
  const TopProduct({required this.name, required this.qty, required this.revenue});

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
        name: j['name'] as String? ?? '-',
        qty: _asInt(j['qty']),
        revenue: _asInt(j['revenue']),
      );
}

class PaymentMethodStat {
  final String method;
  final int total;
  final int count;
  const PaymentMethodStat({required this.method, required this.total, required this.count});

  factory PaymentMethodStat.fromJson(Map<String, dynamic> j) => PaymentMethodStat(
        method: j['method'] as String? ?? '-',
        total: _asInt(j['total']),
        count: _asInt(j['count']),
      );
}

class DashboardSummary {
  final int totalSales;
  final int totalTransactions;
  final int avgTransaction;
  final int totalRefunds;
  final int totalCancels;
  final List<TopProduct> topProducts;
  final List<PaymentMethodStat> paymentBreakdown;

  const DashboardSummary({
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.avgTransaction = 0,
    this.totalRefunds = 0,
    this.totalCancels = 0,
    this.topProducts = const [],
    this.paymentBreakdown = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(Object? v, T Function(Map<String, dynamic>) f) =>
        v is List ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList() : <T>[];
    return DashboardSummary(
      totalSales: _asInt(j['total_sales']),
      totalTransactions: _asInt(j['total_transactions']),
      avgTransaction: _asInt(j['avg_transaction']),
      totalRefunds: _asInt(j['total_refunds']),
      totalCancels: _asInt(j['total_cancels']),
      topProducts: list(j['top_products'], TopProduct.fromJson),
      paymentBreakdown: list(j['payment_breakdown'], PaymentMethodStat.fromJson),
    );
  }

  int get paymentTotal =>
      paymentBreakdown.fold(0, (sum, p) => sum + p.total);
}

class DashboardService {
  static Future<DashboardSummary> summary() async {
    final res = await DioClient.instance.dio.get('/dashboard/summary');
    if (res.data['success'] == true && res.data['data'] != null) {
      return DashboardSummary.fromJson(Map<String, dynamic>.from(res.data['data']));
    }
    throw Exception(res.data['message'] ?? 'Gagal memuat dashboard');
  }
}

final dashboardSummaryProvider =
    FutureProvider<DashboardSummary>((ref) => DashboardService.summary());
