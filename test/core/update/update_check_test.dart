import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/providers/app_version_provider.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/core/update/update_suggestion_dialog.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _version = '1.0.2';

VersionVerdict _verdict(UpdateStatus status, {String version = _version}) =>
    VersionVerdict(
      status: status,
      appVersion: version,
      latestVersion: '1.0.3',
      storeUrl: 'https://apps.apple.com/th/app/id6790326601',
      message: 'Please update',
      messageTh: 'กรุณาอัปเดต',
    );

const _store = AppUpdate(
  storeUrl: 'https://apps.apple.com/th/app/id6790326601',
  currentVersion: _version,
  latestVersion: '1.0.4',
);

/// Answers the check as the test says: [backend] (a verdict, null for "no
/// rules" / 404, or [offline] to throw as an unreachable server) and [store].
class _Sources extends UpdateSources {
  _Sources({this.verdict, this.storeUpdate});

  VersionVerdict? verdict;
  var offline = false;
  AppUpdate? storeUpdate;
  var storeAsked = 0;

  @override
  bool get enabled => true;

  @override
  String get platform => 'ios';

  @override
  Future<String> currentVersion() async => _version;

  @override
  Future<String> bundleId() async => 'com.massdrive.customerApp';

  @override
  Future<VersionVerdict?> backend(String version) async {
    if (offline) throw Exception('offline');
    return verdict;
  }

  @override
  Future<AppUpdate?> store(String version) async {
    storeAsked++;
    return storeUpdate;
  }
}

void main() {
  group('decideUpdate', () {
    test('the admin minimum blocks', () {
      final d = decideUpdate(
        currentVersion: _version,
        backend: _verdict(UpdateStatus.force),
      );
      expect(d.force?.latestVersion, '1.0.3');
      expect(d.force?.note('th'), 'กรุณาอัปเดต');
      expect(d.force?.note('en'), 'Please update');
      expect(d.suggest, isNull);
    });

    test('the recommended version only suggests', () {
      final d = decideUpdate(
        currentVersion: _version,
        backend: _verdict(UpdateStatus.suggest),
      );
      expect(d.force, isNull);
      expect(d.suggest?.latestVersion, '1.0.3');
    });

    test('a newer store version suggests, never blocks', () {
      final d = decideUpdate(
        currentVersion: _version,
        backend: _verdict(UpdateStatus.ok),
        store: _store,
      );
      expect(d.force, isNull);
      expect(d.suggest?.latestVersion, '1.0.4');
    });

    test(
      'no rules on the backend (404) and nothing in the store: no update',
      () {
        final d = decideUpdate(currentVersion: _version);
        expect(d.force, isNull);
        expect(d.suggest, isNull);
      },
    );

    test('offline: a cached force for this version still blocks', () {
      final d = decideUpdate(
        currentVersion: _version,
        backendFailed: true,
        cached: _verdict(UpdateStatus.force),
      );
      expect(d.force, isNotNull);
    });

    test('offline: a cached force for another version does not', () {
      final d = decideUpdate(
        currentVersion: _version,
        backendFailed: true,
        cached: _verdict(UpdateStatus.force, version: '1.0.1'),
      );
      expect(d.force, isNull);
    });

    test('offline: a cached OK lets the app run', () {
      final d = decideUpdate(
        currentVersion: _version,
        backendFailed: true,
        cached: _verdict(UpdateStatus.ok),
      );
      expect(d.force, isNull);
      expect(d.suggest, isNull);
    });

    test('a blank admin note falls back to the app text', () {
      const u = AppUpdate(storeUrl: 'x', currentVersion: '1', message: '  ');
      expect(u.note('en'), isNull);
    });
  });

  group('shouldShowSuggestion', () {
    final now = DateTime(2026, 10, 30, 12);
    String shown(String v, DateTime at) => '$v|${at.millisecondsSinceEpoch}';

    test('never shown: show', () {
      expect(shouldShowSuggestion(null, '1.0.3', now), isTrue);
    });

    test('same version within a day: wait', () {
      final last = shown('1.0.3', now.subtract(const Duration(hours: 23)));
      expect(shouldShowSuggestion(last, '1.0.3', now), isFalse);
    });

    test('same version a day later: show again', () {
      final last = shown('1.0.3', now.subtract(const Duration(hours: 24)));
      expect(shouldShowSuggestion(last, '1.0.3', now), isTrue);
    });

    test('a newer version: show at once', () {
      final last = shown('1.0.3', now.subtract(const Duration(minutes: 5)));
      expect(shouldShowSuggestion(last, '1.0.4', now), isTrue);
    });
  });

  group('ForceUpdateNotifier', () {
    late _Sources sources;
    late ProviderContainer c;

    Future<void> setUpContainer([Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues(prefs);
      final p = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          updateSourcesProvider.overrideWithValue(sources),
        ],
      );
      addTearDown(c.dispose);
      c.listen(forceUpdateProvider, (_, _) {});
      c.listen(suggestUpdateProvider, (_, _) {});
    }

    test('FORCE_UPDATE blocks without asking the store', () async {
      sources = _Sources(verdict: _verdict(UpdateStatus.force));
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(forceUpdateProvider)?.latestVersion, '1.0.3');
      expect(sources.storeAsked, 0);
    });

    test('a backend without rules (404) never blocks', () async {
      sources = _Sources(storeUpdate: _store);
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(forceUpdateProvider), isNull);
      expect(c.read(suggestUpdateProvider)?.latestVersion, '1.0.4');
    });

    test('offline after a FORCE answer keeps blocking', () async {
      sources = _Sources(verdict: _verdict(UpdateStatus.force));
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      sources.offline = true;
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(forceUpdateProvider), isNotNull);
    });

    test('offline after an OK answer lets the app run', () async {
      sources = _Sources(verdict: _verdict(UpdateStatus.ok));
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      sources.offline = true;
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(forceUpdateProvider), isNull);
    });

    test('the admin lowering the minimum unblocks on the next check', () async {
      sources = _Sources(verdict: _verdict(UpdateStatus.force));
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      sources.verdict = _verdict(UpdateStatus.ok);
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(forceUpdateProvider), isNull);
    });

    test('a suggestion already shown today is not offered again', () async {
      sources = _Sources(verdict: _verdict(UpdateStatus.suggest));
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(suggestUpdateProvider), isNotNull);
      await c.read(suggestUpdateProvider.notifier).shown();
      await c.read(forceUpdateProvider.notifier).check();
      expect(c.read(suggestUpdateProvider), isNull);
    });

    test('checkIfStale skips a check made moments ago', () async {
      sources = _Sources(storeUpdate: _store);
      await setUpContainer();
      await c.read(forceUpdateProvider.notifier).check();
      await c.read(forceUpdateProvider.notifier).checkIfStale();
      expect(sources.storeAsked, 1);
    });
  });

  testWidgets('"ไว้ทีหลัง" closes the suggestion and keeps the app usable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(suggestUpdateProvider.notifier).offer(_store);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => offerUpdateSuggestion(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateSuggestion')), findsOneWidget);
    expect(
      find.text('อัปเดตเพื่อใช้ฟีเจอร์ใหม่และการแก้ไขล่าสุด'),
      findsOneWidget,
    );

    await tester.tap(find.text('ไว้ทีหลัง'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateSuggestion')), findsNothing);
    expect(container.read(suggestUpdateProvider), isNull);
    expect(prefs.getString('update_suggest_shown'), startsWith('1.0.4|'));
  });

  test('the version shows without the build number', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Mass Delivery',
      packageName: 'com.massdrive.customerApp',
      version: '1.0.3',
      buildNumber: '112',
      buildSignature: '',
    );
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(appVersionProvider.future), '1.0.3');
  });
}
