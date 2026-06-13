import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/shift_model.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/storage/app_storage.dart';

class ShiftNotifier extends AsyncNotifier<ShiftModel?> {
  @override
  Future<ShiftModel?> build() async {
    return _loadActiveShift();
  }

  Future<ShiftModel?> _loadActiveShift() async {
    final row = await LocalDb.instance.getActiveShift();
    if (row == null) return null;
    return ShiftModel.fromDb(row);
  }

  Future<ShiftModel> openShift({
    required int openingCash,
    String? note,
  }) async {
    final storage = AppStorage.instance;
    final shift = ShiftModel(
      id: const Uuid().v4(),
      userId: storage.userId,
      userName: storage.userName ?? 'User',
      userRole: storage.userRole ?? 'karyawan',
      deviceId: storage.deviceId,
      openingCash: openingCash,
      note: note,
      openedAt: DateTime.now(),
      status: 'open',
      syncStatus: 'pending',
    );

    await LocalDb.instance.insertShift(shift.toDb());
    state = AsyncData(shift);
    return shift;
  }

  Future<void> closeShift({
    required int actualCash,
    String? note,
  }) async {
    final current = state.value;
    if (current == null) return;

    await LocalDb.instance.closeShift(
      current.id,
      DateTime.now().toIso8601String(),
      note ?? '',
    );

    state = const AsyncData(null);
  }

  bool get hasActiveShift => state.value != null;
  ShiftModel? get activeShift => state.value;
}

final shiftProvider =
    AsyncNotifierProvider<ShiftNotifier, ShiftModel?>(ShiftNotifier.new);

/// Simple bool — true if there is an open shift
final hasActiveShiftProvider = Provider<bool>((ref) {
  return ref.watch(shiftProvider).value != null;
});

final activeShiftProvider = Provider<ShiftModel?>((ref) {
  return ref.watch(shiftProvider).value;
});
