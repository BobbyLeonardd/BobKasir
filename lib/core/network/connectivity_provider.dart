import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityStatus build() {
    _init();
    ref.onDispose(() => _subscription?.cancel());
    return ConnectivityStatus.online; // optimistic default
  }

  Future<void> _init() async {
    // Check current status immediately
    final results = await Connectivity().checkConnectivity();
    state = _fromResults(results);

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      state = _fromResults(results);
    });
  }

  ConnectivityStatus _fromResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  bool get isOnline => state == ConnectivityStatus.online;
  bool get isOffline => state == ConnectivityStatus.offline;
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  ConnectivityNotifier.new,
);

/// Simple bool selector
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == ConnectivityStatus.online;
});

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == ConnectivityStatus.offline;
});
