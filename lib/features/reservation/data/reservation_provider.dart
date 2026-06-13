import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reservation_model.dart';

class ReservationNotifier extends Notifier<List<ReservationModel>> {
  @override
  List<ReservationModel> build() {
    // Sample data
    return [
      ReservationModel(
        customerName: 'Budi Santoso',
        phone: '08123456789',
        reservationDate: DateTime.now().add(const Duration(days: 1)),
        reservationTime: const TimeOfDay(hour: 19, minute: 0),
        partySize: 4,
        tableNumber: '5',
        note: 'Anniversary dinner',
        status: ReservationStatus.confirmed,
      ),
      ReservationModel(
        customerName: 'Sari Dewi',
        phone: '08987654321',
        reservationDate: DateTime.now().add(const Duration(days: 2)),
        reservationTime: const TimeOfDay(hour: 12, minute: 30),
        partySize: 2,
        status: ReservationStatus.pending,
      ),
    ];
  }

  void add(ReservationModel reservation) {
    state = [...state, reservation];
  }

  void update(String id, ReservationModel updated) {
    state = state.map((r) => r.id == id ? updated : r).toList();
  }

  void updateStatus(String id, ReservationStatus status) {
    state = state.map((r) {
      if (r.id != id) return r;
      return r.copyWith(status: status);
    }).toList();
  }

  void delete(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  List<ReservationModel> getByDate(DateTime date) {
    return state.where((r) =>
      r.reservationDate.year == date.year &&
      r.reservationDate.month == date.month &&
      r.reservationDate.day == date.day,
    ).toList();
  }
}

final reservationProvider =
    NotifierProvider<ReservationNotifier, List<ReservationModel>>(
  ReservationNotifier.new,
);

final todayReservationsProvider = Provider<List<ReservationModel>>((ref) {
  final today = DateTime.now();
  return ref.watch(reservationProvider.notifier).getByDate(today);
});
