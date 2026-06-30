import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider((ref) => ConnectivityService());

/// Stream-based connectivity watcher. True = online, false = offline.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit initial state
  final initial = await connectivity.checkConnectivity();
  yield _isOnline(initial);
  // Stream subsequent changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield _isOnline(result);
  }
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

class ConnectivityService {
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _isOnline(results);
  }
}
