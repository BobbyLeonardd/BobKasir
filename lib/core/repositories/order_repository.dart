// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../providers/app_providers.dart';
import '../services/api_client.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

final orderRepositoryProvider = Provider((ref) {
  final api = ref.read(apiClientProvider);
  final db = ref.read(appDatabaseProvider);
  return OrderRepository(api, db);
});

class OrderRepository {
  final ApiClient _api;
  final AppDatabase _db;
  OrderRepository(this._api, this._db);

  Future<Map<String, dynamic>> createOrder({
    required String tenantId,
    required String userId,
    required String cashierName,
    required List<CartItem> items,
    required List<SplitPayment> payments,
    String? customerName,
    String? tableNumber,
    String? notes,
  }) async {
    final localId = const Uuid().v4();
    final total = items.fold(0.0, (s, i) => s + i.subtotal);

    final order = OrdersTableCompanion.insert(
      id: localId,
      tenantId: tenantId,
      userId: userId,
      cashierName: cashierName,
      customerName: drift.Value(customerName),
      tableNumber: drift.Value(tableNumber),
      notes: drift.Value(notes),
      total: total,
      status: 'completed',
      localId: drift.Value(localId),
      syncStatus: const drift.Value(0), // pending
      createdAt: DateTime.now(),
    );

    final orderItems = items.map((i) => OrderItemsTableCompanion.insert(
      orderId: localId,
      productId: i.productId,
      productName: i.productName,
      price: i.price,
      qty: i.qty,
      notes: drift.Value(i.notes),
    )).toList();

    int idx = 1;
    final orderPayments = payments.map((p) => OrderPaymentsTableCompanion.insert(
      orderId: localId,
      method: p.method.label,
      amount: p.amount,
      changeAmount: drift.Value(p.change),
      splitIndex: idx++,
    )).toList();

    await _db.insertOrderWithDetails(order, orderItems, orderPayments);

    return {'status': 'success', 'message': 'Disimpan offline', 'data': {'id': localId}};
  }

  Future<List<OrderModel>> getOrders({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? cashierId,
    int page = 1,
  }) async {
    final resp = await _api.get('/orders', params: {
      if (status != null) 'status': status,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (cashierId != null) 'cashier_id': cashierId,
      'page': page,
    });
    final list = (resp.data['data']['data'] ?? resp.data['data']) as List;
    return list.map((j) => _orderFromJson(j as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrder(String id) async {
    final resp = await _api.get('/orders/$id');
    return _orderFromJson(resp.data['data']);
  }

  Future<void> cancelOrder(String id, String reason) async {
    await _api.post('/orders/$id/cancel', data: {'reason': reason});
  }

  Future<void> requestCancel(String id, String reason) async {
    await _api.post('/orders/$id/request-cancel', data: {'reason': reason});
  }

  Future<void> approveCancel(String id) async {
    await _api.post('/orders/$id/approve-cancel');
  }

  Future<void> rejectCancel(String id) async {
    await _api.post('/orders/$id/reject-cancel');
  }

  Future<Map<String, dynamic>> syncOrders(List<Map<String, dynamic>> orders) async {
    final resp = await _api.post('/sync/orders', data: {'orders': orders});
    return resp.data;
  }

  OrderModel _orderFromJson(Map<String, dynamic> j) {
    final itemList = (j['items'] as List? ?? []).map((i) => CartItem(
          productId: i['product_id']?.toString() ?? '',
          productName: i['product_name'],
          price: (i['price'] as num).toDouble(),
          qty: i['qty'],
          notes: i['notes'],
        )).toList();

    final paymentList = (j['payments'] as List? ?? []).map((p) => SplitPayment(
          method: _parseMethod(p['method']),
          amount: (p['amount'] as num).toDouble(),
          change: (p['change_amount'] as num? ?? 0).toDouble(),
          methodLabel: p['method'],
        )).toList();

    return OrderModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id'].toString(),
      userId: j['user_id'].toString(),
      cashierName: j['cashier_name'] ?? '',
      customerName: j['customer_name'],
      tableNumber: j['table_number'],
      notes: j['notes'],
      total: (j['total'] as num).toDouble(),
      items: itemList,
      payments: paymentList,
      status: _parseStatus(j['status']),
      createdAt: DateTime.parse(j['created_at']),
    );
  }

  OrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'request_cancel':
        return OrderStatus.requestCancel;
      default:
        return OrderStatus.open;
    }
  }

  PaymentMethod _parseMethod(String? m) {
    switch (m?.toLowerCase()) {
      case 'tunai':
      case 'cash':
        return PaymentMethod.cash;
      case 'qris':
        return PaymentMethod.qris;
      case 'debit':
        return PaymentMethod.debit;
      case 'e-wallet':
      case 'ewallet':
        return PaymentMethod.eWallet;
      default:
        return PaymentMethod.other;
    }
  }
}
