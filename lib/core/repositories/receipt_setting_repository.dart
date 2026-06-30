import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final receiptSettingRepositoryProvider =
    Provider((ref) => ReceiptSettingRepository(ref.read(apiClientProvider)));

class ReceiptSettingModel {
  final String shopName;
  final String? address;
  final String? phone;
  final String? note;
  final String? footer;
  final String paperWidth; // '58' | '80'
  final String? logoUrl;

  const ReceiptSettingModel({
    required this.shopName,
    this.address,
    this.phone,
    this.note,
    this.footer,
    this.paperWidth = '58',
    this.logoUrl,
  });

  factory ReceiptSettingModel.fromJson(Map<String, dynamic> j) {
    return ReceiptSettingModel(
      shopName: j['shop_name'] ?? '',
      address: j['address'],
      phone: j['phone'],
      note: j['note'],
      footer: j['footer'],
      paperWidth: j['paper_width']?.toString() ?? '58',
      logoUrl: j['logo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'shop_name': shopName,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (note != null) 'note': note,
        if (footer != null) 'footer': footer,
        'paper_width': paperWidth,
      };
}

class ReceiptSettingRepository {
  final ApiClient _api;
  ReceiptSettingRepository(this._api);

  Future<ReceiptSettingModel> get() async {
    final resp = await _api.get('/receipt-settings');
    return ReceiptSettingModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<ReceiptSettingModel> update(ReceiptSettingModel settings) async {
    final resp = await _api.put('/receipt-settings', data: settings.toJson());
    return ReceiptSettingModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }
}
