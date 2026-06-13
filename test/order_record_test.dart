import 'package:flutter_test/flutter_test.dart';
import 'package:bobkasir/features/orders/domain/order_record.dart';

/// The sync payload is the contract the server uses to recreate an order and
/// recompute money (#2/#3). It must carry only raw inputs — never client totals.
void main() {
  OrderRecord buildRecord() => OrderRecord(
        id: 'o1',
        localOrderId: 'o1',
        orderNumber: 'BK-OFFLINE-d1-123',
        cashierName: 'Kasir',
        cashierRole: 'owner',
        subtotal: 50000,
        discountTotal: 5000,
        taxTotal: 4500,
        serviceChargeTotal: 0,
        grandTotal: 49500,
        paidAmount: 50000,
        changeAmount: 500,
        paymentMethod: 'Cash',
        orderedAt: DateTime.parse('2026-06-11T10:00:00.000'),
        customerName: 'Budi',
        tableNumber: '5',
        note: 'pedas',
        items: const [
          OrderItemRecord(
            id: 'i1',
            orderId: 'o1',
            productId: 'p1',
            productName: 'Latte',
            price: 25000,
            qty: 2,
            discount: 0,
            note: 'less sugar',
            subtotal: 50000,
          ),
        ],
        payments: const [
          OrderPaymentRecord(id: 'pay1', orderId: 'o1', method: 'Cash', amount: 50000),
        ],
      );

  group('OrderRecord.toSyncPayload', () {
    test('carries raw order fields', () {
      final p = buildRecord().toSyncPayload();

      expect(p['local_order_id'], 'o1');
      expect(p['ordered_at'], '2026-06-11T10:00:00.000');
      expect(p['customer_name'], 'Budi');
      expect(p['table_number'], '5');
      expect(p['note'], 'pedas');
      expect(p['discount_total'], 5000);
      expect(p['tax_total'], 4500);
      expect(p['service_charge_total'], 0);
    });

    test('does NOT send client-computed subtotal/grand_total', () {
      final p = buildRecord().toSyncPayload();

      // Server is authoritative for these — sending them would be a footgun.
      expect(p.containsKey('subtotal'), isFalse);
      expect(p.containsKey('grand_total'), isFalse);
      expect(p.containsKey('paid_amount'), isFalse);
      expect(p.containsKey('change_amount'), isFalse);
    });

    test('maps items with product reference and unit price', () {
      final items = buildRecord().toSyncPayload()['items'] as List;

      expect(items, hasLength(1));
      final item = items.first as Map;
      expect(item['product_id'], 'p1');
      expect(item['product_name'], 'Latte');
      expect(item['price'], 25000);
      expect(item['qty'], 2);
      expect(item['discount'], 0);
      expect(item['note'], 'less sugar');
      // Per-line subtotal is recomputed server-side, not trusted from client.
      expect(item.containsKey('subtotal'), isFalse);
    });

    test('maps payments (supports split)', () {
      final pays = buildRecord().toSyncPayload()['payments'] as List;

      expect(pays, hasLength(1));
      expect((pays.first as Map)['method'], 'Cash');
      expect((pays.first as Map)['amount'], 50000);
    });
  });
}
