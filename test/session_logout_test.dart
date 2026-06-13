import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bobkasir/core/storage/app_storage.dart';
import 'package:bobkasir/core/network/session_events.dart';
import 'package:bobkasir/features/auth/data/auth_provider.dart';
import 'package:bobkasir/features/auth/domain/user_model.dart';

/// Guards H3: a server 401 (token expired/revoked) must drop the in-memory
/// session so the router redirects to login — not just clear storage silently.
void main() {
  const user = UserModel(
    id: '1',
    name: 'Owner',
    email: 'o@example.com',
    role: UserRole.owner,
    businessId: 'b1',
    businessName: 'Biz',
  );

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppStorage.instance.init();
  });

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('unauthorized event logs an authenticated user out', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.onLoginSuccess(token: 'tok', user: user);
    expect(container.read(authProvider).isAuthenticated, isTrue);

    SessionEvents.instance.notifyUnauthorized();
    await flush();

    expect(container.read(authProvider).isAuthenticated, isFalse);
    expect(AppStorage.instance.token, anyOf(isNull, isEmpty));
  });

  test('unauthorized event is a no-op when not logged in', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(authProvider.notifier); // build()
    await flush();
    expect(container.read(authProvider).isAuthenticated, isFalse);

    SessionEvents.instance.notifyUnauthorized();
    await flush();

    expect(container.read(authProvider).isAuthenticated, isFalse);
  });
}
