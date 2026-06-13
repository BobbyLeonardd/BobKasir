import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/open_bill_model.dart';
import '../../../features/products/domain/product.dart';

class OpenBillNotifier extends Notifier<List<OpenBillModel>> {
  int _counter = 1;

  @override
  List<OpenBillModel> build() => [];

  String _nextBillNumber() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final n = (_counter++).toString().padLeft(3, '0');
    return 'OB-$y$m$d-$n';
  }

  OpenBillModel createBill({
    String? customerName,
    String? tableNumber,
    String? note,
  }) {
    final bill = OpenBillModel(
      billNumber: _nextBillNumber(),
      customerName: customerName,
      tableNumber: tableNumber,
      note: note,
    );
    state = [...state, bill];
    return bill;
  }

  void addItem(String billId, Product product) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      final existing = bill.items.indexWhere((i) => i.productId == product.id);
      final newItems = [...bill.items];
      if (existing >= 0) {
        newItems[existing] = newItems[existing].copyWith(qty: newItems[existing].qty + 1);
      } else {
        newItems.add(OpenBillItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
        ));
      }
      return bill.copyWith(items: newItems, status: OpenBillStatus.updated);
    }).toList();
  }

  void removeItem(String billId, String itemId) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      final newItems = bill.items.where((i) => i.id != itemId).toList();
      return bill.copyWith(items: newItems, status: OpenBillStatus.updated);
    }).toList();
  }

  void updateItemQty(String billId, String itemId, int qty) {
    if (qty <= 0) {
      removeItem(billId, itemId);
      return;
    }
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      final newItems = bill.items.map((i) {
        if (i.id != itemId) return i;
        return i.copyWith(qty: qty);
      }).toList();
      return bill.copyWith(items: newItems, status: OpenBillStatus.updated);
    }).toList();
  }

  void updateItemNote(String billId, String itemId, String note) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      final newItems = bill.items.map((i) {
        if (i.id != itemId) return i;
        return i.copyWith(note: note);
      }).toList();
      return bill.copyWith(items: newItems, status: OpenBillStatus.updated);
    }).toList();
  }

  void updateBillInfo(String billId, {String? customerName, String? tableNumber, String? note}) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      return bill.copyWith(
        customerName: customerName ?? bill.customerName,
        tableNumber: tableNumber ?? bill.tableNumber,
        note: note ?? bill.note,
        status: OpenBillStatus.updated,
      );
    }).toList();
  }

  void checkout(String billId) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      return bill.copyWith(status: OpenBillStatus.checkedOut);
    }).toList();
  }

  void cancel(String billId) {
    state = state.map((bill) {
      if (bill.id != billId) return bill;
      return bill.copyWith(status: OpenBillStatus.cancelled);
    }).toList();
  }

  List<OpenBillModel> get activeBills =>
      state.where((b) => b.status == OpenBillStatus.open || b.status == OpenBillStatus.updated).toList();
}

final openBillProvider = NotifierProvider<OpenBillNotifier, List<OpenBillModel>>(
  OpenBillNotifier.new,
);

final activeBillsProvider = Provider<List<OpenBillModel>>((ref) {
  return ref.watch(openBillProvider.notifier).activeBills;
});

final openBillCountProvider = Provider<int>((ref) {
  return ref.watch(openBillProvider.notifier).activeBills.length;
});
