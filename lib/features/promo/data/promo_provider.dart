import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/promo_model.dart';

class PromoNotifier extends Notifier<List<PromoModel>> {
  @override
  List<PromoModel> build() {
    return [
      PromoModel(
        name: 'Happy Hour 20%',
        type: PromoType.percent,
        discountValue: 20,
        validFrom: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 12, 31),
        description: 'Berlaku setiap hari 14.00–17.00',
      ),
      PromoModel(
        name: 'Voucher BOBKASIR10',
        code: 'BOBKASIR10',
        type: PromoType.nominal,
        discountValue: 10000,
        minTransaction: 50000,
        description: 'Potongan Rp10.000 min. belanja Rp50.000',
      ),
    ];
  }

  void add(PromoModel promo) {
    state = [...state, promo];
  }

  void update(String id, PromoModel updated) {
    state = state.map((p) => p.id == id ? updated : p).toList();
  }

  void toggleActive(String id) {
    state = state.map((p) {
      if (p.id != id) return p;
      p.isActive = !p.isActive;
      return p;
    }).toList();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  /// Validate and apply voucher code, returns the promo or null
  PromoModel? applyCode(String code, int subtotal) {
    final promo = state.where(
      (p) => p.hasCode &&
          p.code!.toUpperCase() == code.toUpperCase() &&
          p.isValid,
    ).firstOrNull;
    if (promo == null) return null;
    if (promo.minTransaction != null && subtotal < promo.minTransaction!) {
      return null;
    }
    return promo;
  }

  void recordUsage(String id) {
    state = state.map((p) {
      if (p.id != id) return p;
      p.usageCount++;
      return p;
    }).toList();
  }

  List<PromoModel> get activePromos =>
      state.where((p) => p.isValid).toList();
}

final promoProvider =
    NotifierProvider<PromoNotifier, List<PromoModel>>(PromoNotifier.new);

final activePromosProvider = Provider<List<PromoModel>>((ref) {
  return ref.watch(promoProvider.notifier).activePromos;
});

/// Applied promo during checkout (null = none)
final appliedPromoProvider = StateProvider<PromoModel?>((ref) => null);
