class CartItem {
  final String productId;
  final String productName;
  final double price;
  int qty;
  String? notes;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.qty = 1,
    this.notes,
  });

  double get subtotal => price * qty;

  CartItem copyWith({int? qty, String? notes}) => CartItem(
        productId: productId,
        productName: productName,
        price: price,
        qty: qty ?? this.qty,
        notes: notes ?? this.notes,
      );
}

enum PaymentMethod { cash, qris, debit, eWallet, other }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.debit:
        return 'Debit';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.other:
        return 'Lainnya';
    }
  }
}

class SplitPayment {
  final PaymentMethod method;
  final double amount;
  final double change;
  final String? methodLabel;

  const SplitPayment({
    required this.method,
    required this.amount,
    this.change = 0,
    this.methodLabel,
  });
}

enum OrderStatus { open, completed, cancelled, requestCancel }

class OrderModel {
  final String id;
  final String tenantId;
  final String userId;
  final String cashierName;
  final String? customerName;
  final String? tableNumber;
  final String? notes;
  final double total;
  final List<CartItem> items;
  final List<SplitPayment> payments;
  final OrderStatus status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.cashierName,
    this.customerName,
    this.tableNumber,
    this.notes,
    required this.total,
    required this.items,
    required this.payments,
    required this.status,
    required this.createdAt,
  });

  double get totalPaid => payments.fold(0, (s, p) => s + p.amount);
  double get change => totalPaid - total;

  static List<OrderModel> mockList = [
    OrderModel(
      id: '#0042',
      tenantId: 't1',
      userId: 'usr_1',
      cashierName: 'Budi Santoso',
      customerName: 'Pak Agus',
      tableNumber: 'Meja 3',
      total: 75000,
      items: [
        CartItem(productId: 'p1', productName: 'Americano', price: 25000, qty: 1),
        CartItem(productId: 'p6', productName: 'Matcha Latte', price: 25000, qty: 2),
      ],
      payments: [const SplitPayment(method: PaymentMethod.cash, amount: 100000, change: 25000)],
      status: OrderStatus.completed,
      createdAt: DateTime(2026, 6, 28, 14, 23),
    ),
    OrderModel(
      id: '#0041',
      tenantId: 't1',
      userId: 'usr_2',
      cashierName: 'Dewi Rahayu',
      total: 28000,
      items: [CartItem(productId: 'p2', productName: 'Cappuccino', price: 28000, qty: 1)],
      payments: [const SplitPayment(method: PaymentMethod.qris, amount: 28000)],
      status: OrderStatus.requestCancel,
      createdAt: DateTime(2026, 6, 28, 13, 50),
    ),
  ];
}

class OpenbillModel {
  final String id;
  final String tenantId;
  final String userId;
  final String label;
  final List<CartItem> items;
  final DateTime createdAt;

  OpenbillModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.label,
    required this.items,
    required this.createdAt,
  });

  double get total => items.fold(0, (s, i) => s + i.subtotal);

  static List<OpenbillModel> mockList = [
    OpenbillModel(
      id: 'ob1',
      tenantId: 't1',
      userId: 'usr_1',
      label: 'Meja 1',
      items: [
        CartItem(productId: 'p1', productName: 'Americano', price: 25000, qty: 1),
        CartItem(productId: 'p9', productName: 'Croissant', price: 22000, qty: 1),
      ],
      createdAt: DateTime(2026, 6, 28, 13, 0),
    ),
    OpenbillModel(
      id: 'ob2',
      tenantId: 't1',
      userId: 'usr_1',
      label: 'Meja 3',
      items: [CartItem(productId: 'p6', productName: 'Matcha Latte', price: 28000, qty: 1)],
      createdAt: DateTime(2026, 6, 28, 13, 30),
    ),
  ];
}

enum ReservationStatus { pending, arrived, cancelled }

class ReservationModel {
  final String id;
  final String tenantId;
  final String customerName;
  final String? tableNumber;
  final DateTime arrivalTime;
  final String? notes;
  final ReservationStatus status;

  const ReservationModel({
    required this.id,
    required this.tenantId,
    required this.customerName,
    this.tableNumber,
    required this.arrivalTime,
    this.notes,
    required this.status,
  });

  static List<ReservationModel> mockList = [
    ReservationModel(
      id: 'res_1',
      tenantId: 't1',
      customerName: 'Budi Santoso',
      tableNumber: 'Meja 5',
      arrivalTime: DateTime(2026, 6, 28, 14, 0),
      notes: 'Ulang tahun, siapkan kue',
      status: ReservationStatus.pending,
    ),
    ReservationModel(
      id: 'res_2',
      tenantId: 't1',
      customerName: 'Dewi',
      tableNumber: 'Meja 2',
      arrivalTime: DateTime(2026, 6, 28, 16, 30),
      status: ReservationStatus.pending,
    ),
  ];
}
