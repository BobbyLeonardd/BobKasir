import 'package:uuid/uuid.dart';

enum PromoType { percent, nominal, buyXGetY, freeShipping }
enum PromoScope { allItems, specificCategory, specificProduct }

class PromoModel {
  final String id;
  final String name;
  final String? code; // voucher code (null = no code required)
  final PromoType type;
  final PromoScope scope;
  final double discountValue; // persen atau nominal
  final int? minTransaction; // min purchase amount
  final int? maxDiscount; // cap untuk persen
  final int? usageLimit; // null = unlimited
  int usageCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  bool isActive;
  final String? description;

  PromoModel({
    String? id,
    required this.name,
    this.code,
    required this.type,
    this.scope = PromoScope.allItems,
    required this.discountValue,
    this.minTransaction,
    this.maxDiscount,
    this.usageLimit,
    this.usageCount = 0,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
    this.description,
  }) : id = id ?? const Uuid().v4();

  bool get hasCode => code != null && code!.isNotEmpty;

  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    return true;
  }

  /// Calculate discount amount for a given subtotal
  int calculateDiscount(int subtotal) {
    if (type == PromoType.percent) {
      final raw = (subtotal * discountValue / 100).round();
      return maxDiscount != null ? raw.clamp(0, maxDiscount!) : raw;
    } else if (type == PromoType.nominal) {
      return discountValue.toInt().clamp(0, subtotal);
    }
    return 0;
  }

  String get typeLabel => switch (type) {
    PromoType.percent => '${discountValue.toStringAsFixed(0)}%',
    PromoType.nominal => 'Rp${discountValue.toStringAsFixed(0)}',
    PromoType.buyXGetY => 'Buy X Get Y',
    PromoType.freeShipping => 'Free Ongkir',
  };
}
