import 'package:customer_app/app.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/core/update/force_update_screen.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _update = StoreUpdate(
  storeUrl: 'https://apps.apple.com/th/app/id1',
  currentVersion: '1.0.2',
  storeVersion: '1.0.3',
);

class _OutdatedNotifier extends ForceUpdateNotifier {
  @override
  StoreUpdate? build() => _update;

  @override
  Future<void> check() async {}
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(isAuthenticated: false);
}

class _FakeHomeController extends HomeController {
  @override
  HomeState build() => const HomeState();
}

class _NoopPush implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('isNewerVersion', () {
    test('compares each part numerically', () {
      expect(isNewerVersion('1.0.3', '1.0.2'), isTrue);
      expect(isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(isNewerVersion('1.1', '1.0.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('same or older is not newer', () {
      expect(isNewerVersion('1.0.2', '1.0.2'), isFalse);
      expect(isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.1', '1.0.2'), isFalse);
    });

    test('ignores a build suffix', () {
      expect(isNewerVersion('1.0.2', '1.0.2+93'), isFalse);
      expect(isNewerVersion('1.0.3+1', '1.0.2+93'), isTrue);
    });
  });

  testWidgets('update screen shows both versions and the update button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [forceUpdateProvider.overrideWith(_OutdatedNotifier.new)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('th'),
          home: ForceUpdateScreen(),
        ),
      ),
    );
    expect(find.text('มีเวอร์ชันใหม่'), findsOneWidget);
    expect(find.text('เวอร์ชันของคุณ 1.0.2 · ล่าสุด 1.0.3'), findsOneWidget);
    expect(find.text('อัปเดตตอนนี้'), findsOneWidget);
  });

  testWidgets('an outdated build is held on the update screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_completed_onboarding': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pushNotificationServiceProvider.overrideWithValue(_NoopPush()),
          authControllerProvider.overrideWith(_FakeAuthController.new),
          homeControllerProvider.overrideWith(_FakeHomeController.new),
          forceUpdateProvider.overrideWith(_OutdatedNotifier.new),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    // Unmount, then let the splash's 2s timer (if it ran) expire.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
