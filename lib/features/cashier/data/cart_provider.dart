import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item.dart';
import '../../products/domain/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Product product) {
    final idx = state.indexWhere((c) => c.product.id == product.id);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(qty: updated[idx].qty + 1);
      state = updated;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void increment(String productId) {
    state = state.map((c) {
      if (c.product.id == productId) return c.copyWith(qty: c.qty + 1);
      return c;
    }).toList();
  }

  void decrement(String productId) {
    final item = state.firstWhere((c) => c.product.id == productId);
    if (item.qty <= 1) {
      remove(productId);
    } else {
      state = state.map((c) {
        if (c.product.id == productId) return c.copyWith(qty: c.qty - 1);
        return c;
      }).toList();
    }
  }

  void remove(String productId) {
    state = state.where((c) => c.product.id != productId).toList();
  }

  void updateNote(String productId, String note) {
    state = state.map((c) {
      if (c.product.id == productId) return c.copyWith(note: note);
      return c;
    }).toList();
  }

  void setItemDiscount(String productId, int discount) {
    state = state.map((c) {
      if (c.product.id == productId) return c.copyWith(itemDiscount: discount);
      return c;
    }).toList();
  }

  void clear() => state = [];

  // Totals
  int get itemCount => state.fold(0, (sum, c) => sum + c.qty);
  int get subtotal => state.fold(0, (sum, c) => sum + c.subtotal); // ignore: unused_element
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// Selectors
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, c) => sum + c.qty);
});

final cartSubtotalProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, c) => sum + c.subtotal);
});
