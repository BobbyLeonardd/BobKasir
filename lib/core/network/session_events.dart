import 'dart:async';

/// Lightweight bridge so the Dio interceptor (which has no Riverpod ref) can
/// tell the auth layer that the server rejected the token (HTTP 401). AuthNotifier
/// listens and clears the in-memory session, which makes the router redirect to
/// login (fixes H3 — 401 previously cleared storage but left state authenticated).
class SessionEvents {
  SessionEvents._();
  static final SessionEvents instance = SessionEvents._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _controller.stream;

  void notifyUnauthorized() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
