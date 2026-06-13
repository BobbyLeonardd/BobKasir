import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bobkasir/core/network/connectivity_provider.dart';
import 'package:bobkasir/features/sync/data/sync_provider.dart';

class _OnlineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityStatus build() => ConnectivityStatus.online;
}

class _OfflineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityStatus build() => ConnectivityStatus.offline;
}

/// In-memory repository — no Dio, no SQLite. Lets us exercise the notifier's
/// orchestration (push / retry / restore) deterministically.
class FakeSyncRepository implements SyncRepository {
  FakeSyncRepository({
    this.pending = const [],
    this.pushSucceeds = true,
    this.orderNumber = 'BK-1',
    this.error = 'boom',
  });

  List<SyncQueueItem> pending;
  bool pushSucceeds;
  String? orderNumber;
  String? error;

  int pushCalls = 0;
  final List<String> syncedLocalIds = [];
  final List<String> failedLocalIds = [];

  @override
  Future<List<SyncQueueItem>> loadPendingOrders() async => pending;

  @override
  Future<SyncPushOutcome> push(SyncQueueItem item) async {
    pushCalls++;
    return pushSucceeds
        ? SyncPushOutcome.ok(orderNumber)
        : SyncPushOutcome.fail(error);
  }

  @override
  Future<void> markSynced(String localId, String? orderNumber) async {
    syncedLocalIds.add(localId);
  }

  @override
  Future<void> markFailed(String localId) async {
    failedLocalIds.add(localId);
  }
}

SyncQueueItem _item(String id) => SyncQueueItem(
      syncId: id,
      localId: id,
      deviceId: 'd1',
      type: SyncItemType.order,
      payload: const {'local_order_id': 'x'},
    );

/// Drain pending microtasks so fire-and-forget async work settles.
Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _container({
  required FakeSyncRepository repo,
  bool online = true,
}) {
  final container = ProviderContainer(overrides: [
    connectivityProvider.overrideWith(
      online ? _OnlineConnectivity.new : _OfflineConnectivity.new,
    ),
    syncRepositoryProvider.overrideWithValue(repo),
  ]);
  return container;
}

void main() {
  group('SyncNotifier.syncAll', () {
    test('marks item synced and persists via repository on success', () async {
      final repo = FakeSyncRepository(orderNumber: 'BK-9');
      final container = _container(repo: repo, online: false);
      addTearDown(container.dispose);

      final notifier = container.read(syncProvider.notifier);
      notifier.enqueue(_item('a')); // offline → no auto sync
      await notifier.syncAll();

      final state = container.read(syncProvider);
      expect(state.syncedCount, 1);
      expect(repo.pushCalls, 1);
      expect(repo.syncedLocalIds, ['a']);
      expect(state.isSyncing, isFalse);
    });

    test('retries then marks failed after 3 attempts', () async {
      final repo = FakeSyncRepository(pushSucceeds: false, error: 'no net');
      final container = _container(repo: repo, online: false);
      addTearDown(container.dispose);

      final notifier = container.read(syncProvider.notifier);
      notifier.enqueue(_item('a'));

      await notifier.syncAll(); // attempt 1 → pending
      expect(container.read(syncProvider).pendingCount, 1);
      await notifier.syncAll(); // attempt 2 → pending
      await notifier.syncAll(); // attempt 3 → failed

      final state = container.read(syncProvider);
      expect(state.failedCount, 1);
      expect(repo.pushCalls, 3);
      expect(repo.failedLocalIds, ['a']);
    });
  });

  group('SyncNotifier.enqueue', () {
    test('pushes immediately when online', () async {
      final repo = FakeSyncRepository();
      final container = _container(repo: repo, online: true);
      addTearDown(container.dispose);

      container.read(syncProvider.notifier).enqueue(_item('a'));
      await _flush();

      expect(repo.pushCalls, 1);
      expect(container.read(syncProvider).syncedCount, 1);
    });
  });

  group('SyncNotifier restore on build', () {
    test('rebuilds queue from local DB and syncs when online', () async {
      final repo = FakeSyncRepository(pending: [_item('x'), _item('y')]);
      final container = _container(repo: repo, online: true);
      addTearDown(container.dispose);

      container.read(syncProvider.notifier); // triggers _restorePending
      await _flush();

      final state = container.read(syncProvider);
      expect(state.queue, hasLength(2));
      expect(state.syncedCount, 2);
      expect(repo.pushCalls, 2);
    });

    test('restores queue but does not sync while offline', () async {
      final repo = FakeSyncRepository(pending: [_item('x')]);
      final container = _container(repo: repo, online: false);
      addTearDown(container.dispose);

      container.read(syncProvider.notifier);
      await _flush();

      final state = container.read(syncProvider);
      expect(state.queue, hasLength(1));
      expect(state.pendingCount, 1);
      expect(repo.pushCalls, 0);
    });
  });
}
