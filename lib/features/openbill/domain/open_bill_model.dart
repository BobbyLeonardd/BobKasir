import 'package:uuid/uuid.dart';

enum OpenBillStatus { open, updated, checkedOut, cancelled }

extension OpenBillStatusExt on OpenBillStatus {
  String get label => switch (this) {
    OpenBillStatus.open => 'Open',
    OpenBillStatus.updated => 'Updated',
    OpenBillStatus.checkedOut => 'Checked Out',
    OpenBillStatus.cancelled => 'Dibatalkan',
  };
}

class OpenBillItem {
  final String id;
  final String productId;
  final String productName;
  final int price;
  int qty;
  String note;
  int discount;

  OpenBillItem({
    String? id,
    required this.productId,
    required this.productName,
    required this.price,
    this.qty = 1,
    this.note = '',
    this.discount = 0,
  }) : id = id ?? const Uuid().v4();

  int get subtotal => (price * qty) - discount;

  OpenBillItem copyWith({int? qty, String? note, int? discount}) =>
      OpenBillItem(
        id: id,
        productId: productId,
        productName: productName,
        price: price,
        qty: qty ?? this.qty,
        note: note ?? this.note,
        discount: discount ?? this.discount,
      );
}

class OpenBillModel {
  final String id;
  final String billNumber;
  final String? customerName;
  final String? tableNumber;
  final String? note;
  final List<OpenBillItem> items;
  final OpenBillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  OpenBillModel({
    String? id,
    required this.billNumber,
    this.customerName,
    this.tableNumber,
    this.note,
    List<OpenBillItem>? items,
    this.status = OpenBillStatus.open,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get subtotal => items.fold(0, (s, i) => s + i.subtotal);
  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  OpenBillModel copyWith({
    String? customerName,
    String? tableNumber,
    String? note,
    List<OpenBillItem>? items,
    OpenBillStatus? status,
  }) =>
      OpenBillModel(
        id: id,
        billNumber: billNumber,
        customerName: customerName ?? this.customerName,
        tableNumber: tableNumber ?? this.tableNumber,
        note: note ?? this.note,
        items: items ?? this.items,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );
}
