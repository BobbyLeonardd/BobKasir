import '../../../features/products/domain/product.dart';

class CartItem {
  final Product product;
  int qty;
  String note;
  int? itemDiscount; // nominal discount on this item

  CartItem({
    required this.product,
    this.qty = 1,
    this.note = '',
    this.itemDiscount,
  });

  int get subtotal {
    final base = product.price * qty;
    return base - (itemDiscount ?? 0);
  }

  CartItem copyWith({int? qty, String? note, int? itemDiscount}) {
    return CartItem(
      product: product,
      qty: qty ?? this.qty,
      note: note ?? this.note,
      itemDiscount: itemDiscount ?? this.itemDiscount,
    );
  }
}
