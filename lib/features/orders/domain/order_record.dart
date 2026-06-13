/// Local order record — mirrors the `local_orders` table (PRD §36.3).
/// Used for offline-first persistence and order history.
class OrderRecord {
  final String id;
  final String localOrderId;
  final String orderNumber;
  final String? customerName;
  final String? tableNumber;
  final String? note;
  final String cashierName;
  final String cashierRole;
  final int subtotal;
  final int discountTotal;
  final int taxTotal;
  final int serviceChargeTotal;
  final int grandTotal;
  final int paidAmount;
  final int changeAmount;
  final String paymentMethod;
  final String paymentStatus; // paid, unpaid
  final String orderStatus; // completed, cancelled, ...
  final String syncStatus; // pending, syncing, synced, failed
  final DateTime orderedAt;
  final List<OrderItemRecord> items;
  final List<OrderPaymentRecord> payments;

  const OrderRecord({
    required this.id,
    required this.localOrderId,
    required this.orderNumber,
    this.customerName,
    this.tableNumber,
    this.note,
    required this.cashierName,
    required this.cashierRole,
    required this.subtotal,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.serviceChargeTotal = 0,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.paymentStatus = 'paid',
    this.orderStatus = 'completed',
    this.syncStatus = 'pending',
    required this.orderedAt,
    this.items = const [],
    this.payments = const [],
  });

  /// Map for `local_orders` insert.
  Map<String, dynamic> toDb() => {
        'id': id,
        'local_order_id': localOrderId,
        'order_number': orderNumber,
        'customer_name': customerName,
        'table_number': tableNumber,
        'note': note,
        'subtotal': subtotal,
        'discount_total': discountTotal,
        'tax_total': taxTotal,
        'service_charge_total': serviceChargeTotal,
        'grand_total': grandTotal,
        'paid_amount': paidAmount,
        'change_amount': changeAmount,
        'payment_status': paymentStatus,
        'order_status': orderStatus,
        'sync_status': syncStatus,
        'payment_method': paymentMethod,
        'cashier_name': cashierName,
        'cashier_role': cashierRole,
        'ordered_at': orderedAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

  factory OrderRecord.fromDb(
    Map<String, dynamic> row, {
    List<OrderItemRecord> items = const [],
    List<OrderPaymentRecord> payments = const [],
  }) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return OrderRecord(
      id: row['id'] as String,
      localOrderId: row['local_order_id'] as String? ?? row['id'] as String,
      orderNumber: row['order_number'] as String? ?? '',
      customerName: row['customer_name'] as String?,
      tableNumber: row['table_number'] as String?,
      note: row['note'] as String?,
      cashierName: row['cashier_name'] as String? ?? '',
      cashierRole: row['cashier_role'] as String? ?? '',
      subtotal: asInt(row['subtotal']),
      discountTotal: asInt(row['discount_total']),
      taxTotal: asInt(row['tax_total']),
      serviceChargeTotal: asInt(row['service_charge_total']),
      grandTotal: asInt(row['grand_total']),
      paidAmount: asInt(row['paid_amount']),
      changeAmount: asInt(row['change_amount']),
      paymentMethod: row['payment_method'] as String? ?? '',
      paymentStatus: row['payment_status'] as String? ?? 'paid',
      orderStatus: row['order_status'] as String? ?? 'completed',
      syncStatus: row['sync_status'] as String? ?? 'pending',
      orderedAt: DateTime.tryParse(row['ordered_at'] as String? ?? '') ??
          DateTime.now(),
      items: items,
      payments: payments,
    );
  }

  /// Items as plain maps for receipt rendering/printing.
  List<Map<String, dynamic>> get itemMaps => items
      .map((i) => {
            'name': i.productName,
            'qty': i.qty,
            'price': i.price,
            'subtotal': i.subtotal,
            'note': i.note ?? '',
          })
      .toList();

  /// Payload sent to POST /api/sync/push (and /api/orders). Totals are
  /// recomputed server-side, so only the raw inputs are sent (PRD §26).
  Map<String, dynamic> toSyncPayload() => {
        'local_order_id': localOrderId,
        'ordered_at': orderedAt.toIso8601String(),
        'customer_name': customerName,
        'table_number': tableNumber,
        'note': note,
        'discount_total': discountTotal,
        'tax_total': taxTotal,
        'service_charge_total': serviceChargeTotal,
        'items': items
            .map((i) => {
                  'product_id': i.productId,
                  'product_name': i.productName,
                  'price': i.price,
                  'qty': i.qty,
                  'discount': i.discount,
                  'note': i.note,
                })
            .toList(),
        'payments': payments
            .map((p) => {'method': p.method, 'amount': p.amount})
            .toList(),
      };
}

class OrderItemRecord {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final int price;
  final int qty;
  final int discount;
  final String? note;
  final int subtotal;

  const OrderItemRecord({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.price,
    required this.qty,
    this.discount = 0,
    this.note,
    required this.subtotal,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'qty': qty,
        'discount': discount,
        'note': note,
        'subtotal': subtotal,
      };

  factory OrderItemRecord.fromDb(Map<String, dynamic> row) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return OrderItemRecord(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      productId: row['product_id'] as String?,
      productName: row['product_name'] as String? ?? '',
      price: asInt(row['price']),
      qty: asInt(row['qty']),
      discount: asInt(row['discount']),
      note: row['note'] as String?,
      subtotal: asInt(row['subtotal']),
    );
  }
}

class OrderPaymentRecord {
  final String id;
  final String orderId;
  final String method;
  final int amount;

  const OrderPaymentRecord({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'order_id': orderId,
        'method': method,
        'amount': amount,
      };

  factory OrderPaymentRecord.fromDb(Map<String, dynamic> row) => OrderPaymentRecord(
        id: row['id'] as String,
        orderId: row['order_id'] as String,
        method: row['method'] as String? ?? '',
        amount: (row['amount'] as num?)?.toInt() ?? 0,
      );
}
