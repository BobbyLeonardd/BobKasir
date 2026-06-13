import 'package:uuid/uuid.dart';

class OutletModel {
  final String id;
  final String businessId;
  final String name;
  final String? address;
  final String? phone;
  bool isActive;

  OutletModel({
    String? id,
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  OutletModel copyWith({
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) =>
      OutletModel(
        id: id,
        businessId: businessId,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        isActive: isActive ?? this.isActive,
      );
}
