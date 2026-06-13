import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bobkasir/core/network/connectivity_provider.dart';
import 'package:bobkasir/features/sync/data/sync_provider.dart';

/// Offline connectivity stub — avoids touching the platform plugin and keeps
/// enqueue from firing a real network sync.
class _OfflineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityStatus build() => ConnectivityStatus.offline;
}

SyncQueueItem _item(String id, {SyncItemStatus status = SyncItemStatus.pending}) =>
    SyncQueueItem(
      syncId: id,
      localId: id,
      deviceId: 'd1',
      type: SyncItemType.order,
      payload: const {'local_order_id': 'x'},
      status: status,
    );

void main() {
  group('SyncItemType.wire', () {
    test('matches the strings the backend SyncController expects', () {
      expect(SyncItemType.order.wire, 'order');
      expect(SyncItemType.openBill.wire, 'open_bill');
      expect(SyncItemType.cancelRequest.wire, 'cancel_request');
      expect(SyncItemType.refundRequest.wire, 'refund_request');
      expect(SyncItemType.shift.wire, 'shift');
      expect(SyncItemType.stockChange.wire, 'stock_change');
      expect(SyncItemType.auditLog.wire, 'audit_log');
    });
  });

  group('SyncState aggregates', () {
    test('counts pending/failed/synced and reports unsynced', () {
      final state = SyncState(queue: [
        _item('a'),
        _item('b'),
        _item('c', status: SyncItemStatus.failed),
        _item('d', status: SyncItemStatus.synced),
      ]);

      expect(state.pendingCount, 2);
      expect(state.failedCount, 1);
      expect(state.syncedCount, 1);
      expect(state.hasUnsynced, isTrue);
    });

    test('hasUnsynced is false when everything is synced', () {
      final state = SyncState(queue: [
        _item('a', status: SyncItemStatus.synced),
        _item('b', status: SyncItemStatus.synced),
      ]);

      expect(state.hasUnsynced, isFalse);
      expect(state.pendingCount, 0);
      expect(state.failedCount, 0);
    });
  });

  group('SyncQueueItem defaults', () {
    test('starts pending with zero retries', () {
      final item = _item('a');
      expect(item.status, SyncItemStatus.pending);
      expect(item.retryCount, 0);
      expect(item.errorMessage, isNull);
    });
  });

  group('SyncNotifier.enqueue', () {
    test('adds to queue and stays pending while offline', () {
      final container = ProviderContainer(overrides: [
        connectivityProvider.overrideWith(_OfflineConnectivity.new),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(syncProvider.notifier);
      notifier.enqueue(_item('s1'));

      final state = container.read(syncProvider);
      expect(state.queue, hasLength(1));
      expect(state.pendingCount, 1);
      expect(container.read(unsyncedCountProvider), 1);
    });
  });
}
