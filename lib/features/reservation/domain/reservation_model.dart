import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ReservationStatus { pending, confirmed, arrived, completed, cancelled, noShow }

extension ReservationStatusExt on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.pending => 'Menunggu',
    ReservationStatus.confirmed => 'Dikonfirmasi',
    ReservationStatus.arrived => 'Hadir',
    ReservationStatus.completed => 'Selesai',
    ReservationStatus.cancelled => 'Dibatalkan',
    ReservationStatus.noShow => 'No Show',
  };
}

class ReservationModel {
  final String id;
  final String customerName;
  final String? phone;
  final DateTime reservationDate;
  final TimeOfDay reservationTime;
  final int partySize;
  final String? tableNumber;
  final String? note;
  ReservationStatus status;
  final DateTime createdAt;
  final String? createdBy;

  ReservationModel({
    String? id,
    required this.customerName,
    this.phone,
    required this.reservationDate,
    required this.reservationTime,
    required this.partySize,
    this.tableNumber,
    this.note,
    this.status = ReservationStatus.pending,
    DateTime? createdAt,
    this.createdBy,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  DateTime get reservationDateTime => DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
        reservationTime.hour,
        reservationTime.minute,
      );

  ReservationModel copyWith({
    String? customerName,
    String? phone,
    DateTime? reservationDate,
    TimeOfDay? reservationTime,
    int? partySize,
    String? tableNumber,
    String? note,
    ReservationStatus? status,
  }) =>
      ReservationModel(
        id: id,
        customerName: customerName ?? this.customerName,
        phone: phone ?? this.phone,
        reservationDate: reservationDate ?? this.reservationDate,
        reservationTime: reservationTime ?? this.reservationTime,
        partySize: partySize ?? this.partySize,
        tableNumber: tableNumber ?? this.tableNumber,
        note: note ?? this.note,
        status: status ?? this.status,
        createdAt: createdAt,
        createdBy: createdBy,
      );
}
