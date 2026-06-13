class ShiftModel {
  final String id;
  final String? userId;
  final String userName;
  final String userRole;
  final String? deviceId;
  final String? outletId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingCash;
  final String? note;
  final String status; // 'open' | 'closed'
  final String syncStatus;

  // Totals computed from orders in this shift
  final int totalCash;
  final int totalQris;
  final int totalTransfer;
  final int totalDebit;
  final int totalEwallet;
  final int totalOther;
  final int totalTransactions;
  final int totalCancelled;
  final int totalRefunded;

  const ShiftModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userRole,
    this.deviceId,
    this.outletId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.note,
    this.status = 'open',
    this.syncStatus = 'pending',
    this.totalCash = 0,
    this.totalQris = 0,
    this.totalTransfer = 0,
    this.totalDebit = 0,
    this.totalEwallet = 0,
    this.totalOther = 0,
    this.totalTransactions = 0,
    this.totalCancelled = 0,
    this.totalRefunded = 0,
  });

  bool get isOpen => status == 'open';

  int get totalSales =>
      totalCash + totalQris + totalTransfer + totalDebit +
      totalEwallet + totalOther;

  /// Cash that should be in drawer = opening cash + cash sales
  int get expectedCash => openingCash + totalCash;

  factory ShiftModel.fromDb(Map<String, dynamic> row) => ShiftModel(
        id: row['id'] as String,
        userId: row['user_id'] as String?,
        userName: row['user_name'] as String? ?? '',
        userRole: row['user_role'] as String? ?? '',
        deviceId: row['device_id'] as String?,
        outletId: row['outlet_id'] as String?,
        openedAt: DateTime.parse(row['opened_at'] as String),
        closedAt: row['closed_at'] != null
            ? DateTime.parse(row['closed_at'] as String)
            : null,
        openingCash: row['opening_cash'] as int? ?? 0,
        note: row['note'] as String?,
        status: row['status'] as String? ?? 'open',
        syncStatus: row['sync_status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toDb() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_role': userRole,
        'device_id': deviceId,
        'outlet_id': outletId,
        'opened_at': openedAt.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
        'opening_cash': openingCash,
        'note': note,
        'status': status,
        'sync_status': syncStatus,
      };
}
