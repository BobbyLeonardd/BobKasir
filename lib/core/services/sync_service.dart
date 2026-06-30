import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'api_client.dart';

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _sub;
  bool _isSyncing = false;

  SyncService(this._db, this._api) {
    _sub = _connectivity.onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) return;
      _syncOrders();
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _syncOrders() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pendingOrders = await _db.getPendingOrders();
      if (pendingOrders.isEmpty) {
        _isSyncing = false;
        return;
      }

      final payload = <Map<String, dynamic>>[];
      for (final order in pendingOrders) {
        final items = await _db.getOrderItems(order.id);
        final payments = await _db.getOrderPayments(order.id);
        
        payload.add({
          'local_id': order.localId ?? order.id,
          'customer_name': order.customerName,
          'table_number': order.tableNumber,
          'notes': order.notes,
          'items': items.map((i) => {
            'product_name': i.productName,
            'qty': i.qty,
            'price': i.price,
            'subtotal': i.price * i.qty,
            'notes': i.notes,
          }).toList(),
          'payments': payments.map((p) => {
            'method': p.method,
            'amount': p.amount,
            'change_amount': p.changeAmount,
            'split_index': p.splitIndex,
          }).toList(),
        });
      }

      final resp = await _api.post('/sync/orders', data: {'orders': payload});
      
      // If success, mark synced
      if (resp.statusCode == 200 || resp.statusCode == 201) {
         for (final order in pendingOrders) {
            await _db.markOrderAsSynced(order.id);
         }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
