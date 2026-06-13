import 'package:uuid/uuid.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/helpers/date_helper.dart';
import '../../cashier/domain/cart_item.dart';
import '../domain/order_record.dart';

/// One payment line for an order (supports split payment, PRD §12.6).
typedef PaymentInput = ({String method, int amount});

/// Persists and reads orders from the local SQLite database (offline-first).
/// Server sync is handled separately via the sync queue (PRD §26).
class OrderService {
  static const _uuid = Uuid();

  /// Build and persist an order (+ items + payments) to LocalDb.
  /// Returns the saved [OrderRecord] for the receipt and history.
  static Future<OrderRecord> createOrder({
    required List<CartItem> cartItems,
    required List<PaymentInput> payments,
    required int subtotal,
    required int discountTotal,
    required int taxTotal,
    required int serviceChargeTotal,
    required int grandTotal,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
    required String cashierName,
    required String cashierRole,
    String? customerName,
    String? tableNumber,
    String? note,
  }) async {
    final storage = AppStorage.instance;
    final deviceId = storage.deviceId ?? 'unknown';
    final orderId = _uuid.v4();
    final orderedAt = DateTime.now();

    final items = cartItems
        .map(
          (c) => OrderItemRecord(
            id: _uuid.v4(),
            orderId: orderId,
            productId: c.product.id,
            productName: c.product.name,
            price: c.product.price,
            qty: c.qty,
            discount: c.itemDiscount ?? 0,
            note: c.note.isEmpty ? null : c.note,
            subtotal: c.subtotal,
          ),
        )
        .toList();

    final paymentRecords = payments
        .where((p) => p.amount > 0)
        .map(
          (p) => OrderPaymentRecord(
            id: _uuid.v4(),
            orderId: orderId,
            method: p.method,
            amount: p.amount,
          ),
        )
        .toList();

    final order = OrderRecord(
      id: orderId,
      localOrderId: orderId,
      orderNumber: DateHelper.offlineOrderNumber(deviceId),
      customerName: customerName,
      tableNumber: tableNumber,
      note: note,
      cashierName: cashierName,
      cashierRole: cashierRole,
      subtotal: subtotal,
      discountTotal: discountTotal,
      taxTotal: taxTotal,
      serviceChargeTotal: serviceChargeTotal,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      orderStatus: 'completed',
      syncStatus: 'pending',
      orderedAt: orderedAt,
      items: items,
      payments: paymentRecords,
    );

    final db = LocalDb.instance;
    await db.insertOrder({
      ...order.toDb(),
      'business_id': storage.businessId,
      'device_id': deviceId,
      'user_id': storage.userId,
    });
    await db.insertOrderItems(items.map((i) => i.toDb()).toList());
    await db.insertOrderPayments(paymentRecords.map((p) => p.toDb()).toList());

    return order;
  }

  /// Recent orders for the history list (without items/payments).
  static Future<List<OrderRecord>> getRecentOrders({int limit = 50}) async {
    final rows = await LocalDb.instance.getOrders(limit: limit);
    return rows.map((r) => OrderRecord.fromDb(r)).toList();
  }

  /// Full order detail (with items and payments) by local id.
  static Future<OrderRecord?> getOrderById(String id) async {
    final db = LocalDb.instance;
    final row = await db.getOrderById(id);
    if (row == null) return null;
    final items =
        (await db.getOrderItems(id)).map(OrderItemRecord.fromDb).toList();
    final payments =
        (await db.getOrderPayments(id)).map(OrderPaymentRecord.fromDb).toList();
    return OrderRecord.fromDb(row, items: items, payments: payments);
  }

  /// Mark an order cancelled locally (PRD §16.4). Sync handled elsewhere.
  static Future<void> cancelOrder(String id) async {
    final db = LocalDb.instance;
    await db.updateOrderStatus(id, 'cancelled');
    await db.updateOrderSyncStatus(id, 'pending');
  }
}
