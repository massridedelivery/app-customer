import 'package:customer_app/app.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts re-arm requests instead of opening a real WebSocket.
class _SpySocket extends SocketService {
  _SpySocket(super.tokenStorage);

  int ensureConnectedCalls = 0;
  int suspendCalls = 0;

  @override
  void ensureConnected() => ensureConnectedCalls++;

  @override
  void suspend() => suspendCalls++;

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

/// Keeps auth state fixed so the socket calls under test can only come from
/// the lifecycle handler, not from a login transition.
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);
}

/// The real service touches FirebaseMessaging.instance in its constructor,
/// which is unavailable off-mobile.
class _NoopPush implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<_SpySocket> _pumpApp(WidgetTester tester, {required bool loggedIn}) async {
  SharedPreferences.setMockInitialValues(
    loggedIn ? {'access_token': 'jwt', 'refresh_token': 'refresh'} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  final socket = _SpySocket(TokenStorage(prefs));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pushNotificationServiceProvider.overrideWithValue(_NoopPush()),
        authControllerProvider.overrideWith(_FakeAuthController.new),
        socketServiceProvider.overrideWithValue(socket),
      ],
      child: const App(),
    ),
  );

  // Let the splash gate's 2s timer fire and hand off, otherwise it is still
  // pending when the tree is torn down. Pump manually (not pumpAndSettle) —
  // the splash pulse animation repeats forever.
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));

  return socket;
}

void _sendToBackgroundAndBack(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  testWidgets('resuming with a session re-arms the socket', (tester) async {
    final socket = await _pumpApp(tester, loggedIn: true);
    final beforeResume = socket.ensureConnectedCalls;

    _sendToBackgroundAndBack(tester);
    await tester.pump();

    expect(
      socket.ensureConnectedCalls,
      greaterThan(beforeResume),
      reason: 'the OS drops the socket while backgrounded — coming back to the '
          'foreground must reconnect it',
    );
  });

  testWidgets('resuming while logged out leaves the socket alone', (
    tester,
  ) async {
    final socket = await _pumpApp(tester, loggedIn: false);

    _sendToBackgroundAndBack(tester);
    await tester.pump();

    expect(socket.ensureConnectedCalls, 0);
  });

  testWidgets('backgrounding suspends the socket', (tester) async {
    final socket = await _pumpApp(tester, loggedIn: true);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(
      socket.suspendCalls,
      1,
      reason: 'retries from the background always fail (the OS revokes network '
          'access) — they must not eat the reconnect budget',
    );
  });

  testWidgets('a transient interruption does not drop the socket', (
    tester,
  ) async {
    final socket = await _pumpApp(tester, loggedIn: true);

    // App switcher / incoming call: inactive without a full background.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(socket.suspendCalls, 0);
  });
}
