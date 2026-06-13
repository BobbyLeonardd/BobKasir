import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/outlet_model.dart';
import '../../../core/storage/app_storage.dart';

class OutletNotifier extends Notifier<List<OutletModel>> {
  @override
  List<OutletModel> build() {
    final bizId = AppStorage.instance.businessId ?? 'biz-001';
    return [
      OutletModel(
        id: 'outlet-main',
        businessId: bizId,
        name: 'Outlet Utama',
        address: 'Jl. Utama No. 1',
        isActive: true,
      ),
    ];
  }

  void add(OutletModel outlet) {
    state = [...state, outlet];
    // TODO: POST /api/outlets
  }

  void update(String id, OutletModel updated) {
    state = state.map((o) => o.id == id ? updated : o).toList();
    // TODO: PUT /api/outlets/{id}
  }

  void toggleActive(String id) {
    state = state.map((o) {
      if (o.id != id) return o;
      return o.copyWith(isActive: !o.isActive);
    }).toList();
  }

  void delete(String id) {
    state = state.where((o) => o.id != id).toList();
  }

  List<OutletModel> get activeOutlets => state.where((o) => o.isActive).toList();
}

final outletProvider =
    NotifierProvider<OutletNotifier, List<OutletModel>>(OutletNotifier.new);

final activeOutletsProvider = Provider<List<OutletModel>>((ref) {
  return ref.watch(outletProvider.notifier).activeOutlets;
});

/// Currently selected outlet (for cashier/orders filtering)
final selectedOutletProvider = StateProvider<OutletModel?>((ref) {
  final outlets = ref.watch(activeOutletsProvider);
  return outlets.isNotEmpty ? outlets.first : null;
});
