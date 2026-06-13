import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum KitchenOrderStatus { waiting, preparing, ready, served }

extension KitchenOrderStatusExt on KitchenOrderStatus {
  String get label => switch (this) {
    KitchenOrderStatus.waiting => 'Menunggu',
    KitchenOrderStatus.preparing => 'Diproses',
    KitchenOrderStatus.ready => 'Siap',
    KitchenOrderStatus.served => 'Disajikan',
  };

  String get emoji => switch (this) {
    KitchenOrderStatus.waiting => '⏳',
    KitchenOrderStatus.preparing => '👨‍🍳',
    KitchenOrderStatus.ready => '✅',
    KitchenOrderStatus.served => '🍽️',
  };
}

class KitchenItem {
  final String productName;
  final int qty;
  final String? note;

  const KitchenItem({
    required this.productName,
    required this.qty,
    this.note,
  });
}

class KitchenOrder {
  final String id;
  final String orderNumber;
  final String? tableNumber;
  final String? customerName;
  final String? orderNote;
  final List<KitchenItem> items;
  KitchenOrderStatus status;
  final DateTime createdAt;
  DateTime? preparedAt;
  DateTime? readyAt;

  KitchenOrder({
    String? id,
    required this.orderNumber,
    this.tableNumber,
    this.customerName,
    this.orderNote,
    required this.items,
    this.status = KitchenOrderStatus.waiting,
    DateTime? createdAt,
    this.preparedAt,
    this.readyAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Duration get waitingTime => DateTime.now().difference(createdAt);

  bool get isUrgent => waitingTime.inMinutes >= 10;
}

class KitchenNotifier extends Notifier<List<KitchenOrder>> {
  @override
  List<KitchenOrder> build() {
    // Sample kitchen orders
    return [
      KitchenOrder(
        orderNumber: 'BK-20260610-0003',
        tableNumber: '3',
        customerName: 'Budi',
        items: const [
          KitchenItem(productName: 'Americano', qty: 2, note: 'Less sugar'),
          KitchenItem(productName: 'Latte', qty: 1),
        ],
        status: KitchenOrderStatus.waiting,
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      KitchenOrder(
        orderNumber: 'BK-20260610-0002',
        tableNumber: '5',
        items: const [
          KitchenItem(productName: 'Nasi Goreng', qty: 1, note: 'Tanpa telur'),
          KitchenItem(productName: 'Es Teh Manis', qty: 2),
        ],
        status: KitchenOrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        preparedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
    ];
  }

  void addOrder(KitchenOrder order) {
    state = [order, ...state];
  }

  void updateStatus(String id, KitchenOrderStatus status) {
    state = state.map((o) {
      if (o.id != id) return o;
      o.status = status;
      if (status == KitchenOrderStatus.preparing) {
        o.preparedAt = DateTime.now();
      } else if (status == KitchenOrderStatus.ready) {
        o.readyAt = DateTime.now();
      }
      return o;
    }).toList();
  }

  void removeServed() {
    state = state.where((o) => o.status != KitchenOrderStatus.served).toList();
  }

  List<KitchenOrder> get activeOrders => state
      .where((o) => o.status != KitchenOrderStatus.served)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

final kitchenProvider =
    NotifierProvider<KitchenNotifier, List<KitchenOrder>>(KitchenNotifier.new);

final activeKitchenOrdersProvider = Provider<List<KitchenOrder>>((ref) {
  return ref.watch(kitchenProvider.notifier).activeOrders;
});
