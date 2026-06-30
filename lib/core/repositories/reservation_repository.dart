// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/order_model.dart';

final reservationRepositoryProvider =
    Provider((ref) => ReservationRepository(ref.read(apiClientProvider)));

class ReservationRepository {
  final ApiClient _api;
  ReservationRepository(this._api);

  Future<List<ReservationModel>> getReservations({String? status}) async {
    final resp = await _api.get('/reservations', params: {
      if (status != null) 'status': status,
    });
    final list = resp.data['data'] as List;
    return list.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ReservationModel> createReservation({
    required String customerName,
    required DateTime arrivalTime,
    String? tableNumber,
    String? notes,
  }) async {
    final resp = await _api.post('/reservations', data: {
      'customer_name': customerName,
      'arrival_time': arrivalTime.toIso8601String(),
      if (tableNumber != null) 'table_number': tableNumber,
      if (notes != null) 'notes': notes,
    });
    return _fromJson(resp.data['data']);
  }

  Future<ReservationModel> updateReservation(String id, {
    String? customerName,
    DateTime? arrivalTime,
    String? tableNumber,
    String? notes,
  }) async {
    final resp = await _api.put('/reservations/$id', data: {
      if (customerName != null) 'customer_name': customerName,
      if (arrivalTime != null) 'arrival_time': arrivalTime.toIso8601String(),
      if (tableNumber != null) 'table_number': tableNumber,
      if (notes != null) 'notes': notes,
    });
    return _fromJson(resp.data['data']);
  }

  Future<ReservationModel> arrive(String id) async {
    final resp = await _api.post('/reservations/$id/arrive');
    return _fromJson(resp.data['data']);
  }

  Future<void> cancel(String id, {String? reason}) async {
    await _api.post('/reservations/$id/cancel', data: {
      if (reason != null) 'reason': reason,
    });
  }

  ReservationModel _fromJson(Map<String, dynamic> j) {
    return ReservationModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id'].toString(),
      customerName: j['customer_name'],
      tableNumber: j['table_number'],
      arrivalTime: DateTime.parse(j['arrival_time']),
      notes: j['notes'],
      status: _parseStatus(j['status']),
    );
  }

  ReservationStatus _parseStatus(String? s) {
    switch (s) {
      case 'arrived':
        return ReservationStatus.arrived;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }
}
