// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/order_model.dart';

final openbillRepositoryProvider =
    Provider((ref) => OpenbillRepository(ref.read(apiClientProvider)));

class OpenbillRepository {
  final ApiClient _api;
  OpenbillRepository(this._api);

  Future<List<OpenbillModel>> getOpenbills() async {
    final resp = await _api.get('/openbills');
    final list = resp.data['data'] as List;
    return list.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<OpenbillModel> createOpenbill(String label, List<CartItem> items) async {
    final resp = await _api.post('/openbills', data: {
      'label': label,
      'items_snapshot': items.map((i) => {
        'product_id': i.productId.isEmpty ? null : i.productId,
        'product_name': i.productName,
        'qty': i.qty,
        'price': i.price.toInt(),
        if (i.notes != null) 'notes': i.notes,
      }).toList(),
    });
    return _fromJson(resp.data['data']);
  }

  Future<OpenbillModel> updateOpenbill(String id, String label, List<CartItem> items) async {
    final resp = await _api.put('/openbills/$id', data: {
      'label': label,
      'items_snapshot': items.map((i) => {
        'product_name': i.productName,
        'qty': i.qty,
        'price': i.price.toInt(),
        if (i.notes != null) 'notes': i.notes,
      }).toList(),
    });
    return _fromJson(resp.data['data']);
  }

  Future<void> deleteOpenbill(String id) async {
    await _api.delete('/openbills/$id');
  }

  Future<Map<String, dynamic>> checkout(
    String id, {
    required List<SplitPayment> payments,
    String? customerName,
    String? tableNumber,
    String? notes,
  }) async {
    final resp = await _api.post('/openbills/$id/checkout', data: {
      if (customerName != null) 'customer_name': customerName,
      if (tableNumber != null) 'table_number': tableNumber,
      if (notes != null) 'notes': notes,
      'payments': payments.asMap().entries.map((e) => {
        'method': e.value.method.label,
        'amount': e.value.amount.toInt(),
        'change_amount': e.value.change.toInt(),
      }).toList(),
    });
    return resp.data;
  }

  OpenbillModel _fromJson(Map<String, dynamic> j) {
    final snapshotList = (j['items_snapshot'] as List? ?? []);
    final items = snapshotList.map((i) => CartItem(
          productId: i['product_id']?.toString() ?? '',
          productName: i['product_name'],
          price: (i['price'] as num).toDouble(),
          qty: i['qty'],
          notes: i['notes'],
        )).toList();

    return OpenbillModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id'].toString(),
      userId: j['user_id'].toString(),
      label: j['label'] ?? 'Tanpa nama',
      items: items,
      createdAt: DateTime.parse(j['created_at']),
    );
  }
}
