import 'package:customer_app/app.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:customer_app/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth stays logged-out and unchanged for the whole test, so the only thing
/// that could send us back to /splash is a lifecycle reset (the removed bug).
class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);
}

/// The real service touches FirebaseMessaging.instance in its constructor,
/// which is unavailable off-mobile. This stub keeps App.initState().init()
/// working without Firebase.
class _NoopPush implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'returning to foreground does not re-show the splash screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            pushNotificationServiceProvider.overrideWithValue(_NoopPush()),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: const App(),
        ),
      );

      // Cold start lands on the splash gate.
      expect(find.byType(SplashScreen), findsOneWidget);

      // Splash auto-advances after its 2s delay. Pump manually (not
      // pumpAndSettle) because the splash pulse animation repeats forever.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // router processes splashShown=true redirect
      await tester.pump(const Duration(seconds: 1)); // route transition

      expect(find.byType(SplashScreen), findsNothing);
      expect(
        find.byType(OnboardingScreen),
        findsOneWidget,
        reason: 'splash should hand off to onboarding once shown',
      );

      // Simulate switching away from the app and back.
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Regression guard: pre-fix, resume reset splashShown=false and forced a
      // redirect back to /splash. It must stay put now.
      expect(
        find.byType(SplashScreen),
        findsNothing,
        reason: 'app must not re-show splash when brought back to foreground',
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );
}
