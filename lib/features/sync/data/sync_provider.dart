import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/storage/local_db.dart';
import '../../orders/data/order_service.dart';

enum SyncItemType { order, openBill, cancelRequest, refundRequest, shift, stockChange, auditLog }

/// Wire value sent to the backend `type` field (matches SyncController).
extension SyncItemTypeWire on SyncItemType {
  String get wire => switch (this) {
        SyncItemType.order => 'order',
        SyncItemType.openBill => 'open_bill',
        SyncItemType.cancelRequest => 'cancel_request',
        SyncItemType.refundRequest => 'refund_request',
        SyncItemType.shift => 'shift',
        SyncItemType.stockChange => 'stock_change',
        SyncItemType.auditLog => 'audit_log',
      };
}

enum SyncItemStatus { pending, syncing, synced, failed }

class SyncQueueItem {
  final String syncId;
  final String localId;
  final String deviceId;
  final SyncItemType type;
  final Map<String, dynamic> payload;
  SyncItemStatus status;
  final DateTime createdAt;
  int retryCount;
  String? errorMessage;

  SyncQueueItem({
    required this.syncId,
    required this.localId,
    required this.deviceId,
    required this.type,
    required this.payload,
    this.status = SyncItemStatus.pending,
    DateTime? createdAt,
    this.retryCount = 0,
    this.errorMessage,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SyncState {
  final List<SyncQueueItem> queue;
  final bool isSyncing;
  final DateTime? lastSyncAt;

  const SyncState({
    this.queue = const [],
    this.isSyncing = false,
    this.lastSyncAt,
  });

  int get pendingCount =>
      queue.where((i) => i.status == SyncItemStatus.pending).length;
  int get failedCount =>
      queue.where((i) => i.status == SyncItemStatus.failed).length;
  int get syncedCount =>
      queue.where((i) => i.status == SyncItemStatus.synced).length;

  bool get hasUnsynced => pendingCount > 0 || failedCount > 0;

  SyncState copyWith({
    List<SyncQueueItem>? queue,
    bool? isSyncing,
    DateTime? lastSyncAt,
  }) =>
      SyncState(
        queue: queue ?? this.queue,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    // Listen for connectivity restored → auto sync
    ref.listen(connectivityProvider, (prev, next) {
      if (prev == ConnectivityStatus.offline &&
          next == ConnectivityStatus.online) {
        _autoSync();
      }
    });
    // Rebuild the queue from orders still pending in local DB so unsynced
    // transactions survive an app restart (PRD §26.3).
    _restorePending();
    return const SyncState();
  }

  void enqueue(SyncQueueItem item) {
    state = state.copyWith(queue: [...state.queue, item]);
    // Push immediately when online; otherwise it waits in the queue.
    if (ref.read(connectivityProvider) == ConnectivityStatus.online) {
      syncAll();
    }
  }

  /// Reload orders with sync_status pending/failed from local DB into the queue.
  Future<void> _restorePending() async {
    try {
      final restored =
          await ref.read(syncRepositoryProvider).loadPendingOrders();
      if (restored.isEmpty) return;
      final existing = state.queue.map((q) => q.localId).toSet();
      final newItems =
          restored.where((r) => !existing.contains(r.localId)).toList();
      if (newItems.isEmpty) return;
      state = state.copyWith(queue: [...state.queue, ...newItems]);
      if (ref.read(connectivityProvider) == ConnectivityStatus.online) {
        await syncAll();
      }
    } catch (_) {
      // Storage unavailable — queue stays empty; orders remain persisted.
    }
  }

  Future<void> syncAll() async {
    if (state.isSyncing) return;
    final pending = state.queue
        .where((i) =>
            i.status == SyncItemStatus.pending ||
            i.status == SyncItemStatus.failed)
        .toList();
    if (pending.isEmpty) return;

    state = state.copyWith(isSyncing: true);

    for (final item in pending) {
      await _syncItem(item);
    }

    state = state.copyWith(
      isSyncing: false,
      lastSyncAt: DateTime.now(),
    );
  }

  Future<void> _syncItem(SyncQueueItem item) async {
    _updateStatus(item.syncId, SyncItemStatus.syncing);
    final repo = ref.read(syncRepositoryProvider);
    final outcome = await repo.push(item);

    if (outcome.success) {
      _updateStatus(item.syncId, SyncItemStatus.synced);
      // Reflect in local DB: mark synced + adopt server order number.
      if (item.type == SyncItemType.order) {
        await repo.markSynced(item.localId, outcome.orderNumber);
      }
      return;
    }

    item.retryCount++;
    item.errorMessage = outcome.error;
    if (item.retryCount >= 3) {
      _updateStatus(item.syncId, SyncItemStatus.failed, error: outcome.error);
      if (item.type == SyncItemType.order) {
        await repo.markFailed(item.localId);
      }
    } else {
      _updateStatus(item.syncId, SyncItemStatus.pending);
    }
  }

  void _updateStatus(String syncId, SyncItemStatus status,
      {String? error}) {
    final updated = state.queue.map((i) {
      if (i.syncId == syncId) {
        i.status = status;
        if (error != null) i.errorMessage = error;
      }
      return i;
    }).toList();
    state = state.copyWith(queue: updated);
  }

  Future<void> retryFailed() async {
    for (final item in state.queue) {
      if (item.status == SyncItemStatus.failed) {
        item.status = SyncItemStatus.pending;
        item.retryCount = 0;
      }
    }
    state = state.copyWith(queue: [...state.queue]);
    await syncAll();
  }

  void _autoSync() {
    syncAll();
  }

  void clearSynced() {
    state = state.copyWith(
      queue: state.queue
          .where((i) => i.status != SyncItemStatus.synced)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Repository — isolates all I/O (HTTP + local DB) so SyncNotifier stays pure
// orchestration and can be unit-tested with a fake (override syncRepositoryProvider).
// ─────────────────────────────────────────────

class SyncPushOutcome {
  final bool success;
  final String? orderNumber;
  final String? error;

  const SyncPushOutcome.ok([this.orderNumber])
      : success = true,
        error = null;
  const SyncPushOutcome.fail(this.error)
      : success = false,
        orderNumber = null;
}

abstract class SyncRepository {
  /// Rebuild queue items from orders still pending/failed in local storage.
  Future<List<SyncQueueItem>> loadPendingOrders();

  /// Push one queue item to the server.
  Future<SyncPushOutcome> push(SyncQueueItem item);

  /// Persist a successful sync locally (adopt server order number).
  Future<void> markSynced(String localId, String? orderNumber);

  /// Persist a permanently failed sync locally.
  Future<void> markFailed(String localId);
}

/// Production implementation backed by Dio, local SQLite and device storage.
class DefaultSyncRepository implements SyncRepository {
  const DefaultSyncRepository();

  @override
  Future<List<SyncQueueItem>> loadPendingOrders() async {
    final rows = await LocalDb.instance.getPendingSyncOrders();
    if (rows.isEmpty) return const [];
    final device = AppStorage.instance.deviceId ?? 'unknown';
    final items = <SyncQueueItem>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final order = await OrderService.getOrderById(id);
      if (order == null) continue;
      items.add(SyncQueueItem(
        syncId: 'sync-$id',
        localId: id,
        deviceId: device,
        type: SyncItemType.order,
        payload: order.toSyncPayload(),
      ));
    }
    return items;
  }

  @override
  Future<SyncPushOutcome> push(SyncQueueItem item) async {
    try {
      final res = await DioClient.instance.dio.post('/sync/push', data: {
        'device_id': item.deviceId,
        'items': [
          {
            'sync_id': item.syncId,
            'local_id': item.localId,
            'type': item.type.wire,
            'payload': item.payload,
          }
        ],
      });

      final body = res.data;
      final results = (body is Map && body['data'] is Map)
          ? body['data']['results']
          : null;
      final first = (results is List && results.isNotEmpty)
          ? results.first as Map
          : null;
      final status = first?['status'] as String?;

      if (body is Map &&
          body['success'] == true &&
          (status == 'synced' || status == 'already_synced')) {
        return SyncPushOutcome.ok(first?['order_number'] as String?);
      }
      return SyncPushOutcome.fail(
          (first?['error'] ?? (body is Map ? body['message'] : null) ?? 'Sync gagal')
              .toString());
    } catch (e) {
      return SyncPushOutcome.fail(e.toString());
    }
  }

  @override
  Future<void> markSynced(String localId, String? orderNumber) async {
    await LocalDb.instance.markOrderSynced(localId, orderNumber);
  }

  @override
  Future<void> markFailed(String localId) async {
    await LocalDb.instance.updateOrderSyncStatus(localId, 'failed');
  }
}

final syncRepositoryProvider =
    Provider<SyncRepository>((ref) => const DefaultSyncRepository());

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

// Badge count for unsynced items
final unsyncedCountProvider = Provider<int>((ref) {
  return ref.watch(syncProvider).pendingCount +
      ref.watch(syncProvider).failedCount;
});
