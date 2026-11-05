import 'dart:convert';

import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/features/popup/app_popup.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements AppPopupRepository {
  _Repo(this.items);

  List<AppPopup> items;
  int calls = 0;

  @override
  Future<List<AppPopup>> active() async {
    calls++;
    return items;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppPopup _popup(
  String id, {
  Object version = 1,
  Map<String, dynamic>? action,
}) => AppPopup.fromJson({
  'id': id,
  'version': version,
  'image_url': 'https://cdn.test/$id.png',
  'action': action,
})!;

class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        key: const Key('check'),
        onPressed: () => maybeShowAppPopup(context, ref),
        child: const Text('home'),
      ),
    ),
  );
}

Future<({GoRouter router, SharedPreferences prefs})> _pump(
  WidgetTester tester,
  _Repo repo, {
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/main',
    routes: [
      GoRoute(path: '/main', builder: (_, _) => const _Home()),
      GoRoute(
        path: '/rewards',
        builder: (_, _) => const Scaffold(body: Text('rewards page')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appPopupRepositoryProvider.overrideWithValue(repo),
        forceUpdateProvider.overrideWith(_NoUpdate.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
      ),
    ),
  );
  return (router: router, prefs: prefs);
}

class _NoUpdate extends ForceUpdateNotifier {
  @override
  AppUpdate? build() => null;
}

Future<void> _check(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('check')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => appPopupPrecache = (_, _) async => true);

  test('parses items; skips ones without id or image; action optional', () {
    expect(AppPopup.fromJson({'id': 'a', 'image_url': ''}), isNull);
    expect(AppPopup.fromJson({'image_url': 'x'}), isNull);
    final p = _popup(
      'a',
      version: 3,
      action: {'type': 'deeplink', 'value': '/rewards', 'button_text': 'ดูเลย'},
    );
    expect(p.version, '3');
    expect(p.sessionKey, 'a:3');
    expect(p.action!.buttonText, 'ดูเลย');
    expect(_popup('b').action, isNull);
  });

  testWidgets('✕ unticked: gone for the session only', (tester) async {
    final repo = _Repo([_popup('a')]);
    final env = await _pump(tester, repo);
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appPopupClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appPopupImage')), findsNothing);
    expect(env.prefs.getString(AppPopupStore.prefsKey), isNull);
  });

  testWidgets('✕ ticked: never again for this version; a new version shows', (
    tester,
  ) async {
    final repo = _Repo([_popup('a')]);
    final env = await _pump(tester, repo);
    await _check(tester);
    await tester.tap(find.byKey(const Key('appPopupDontShow')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('appPopupClose')));
    await tester.pumpAndSettle();
    expect(jsonDecode(env.prefs.getString(AppPopupStore.prefsKey)!), {
      'a': '1',
    });

    final store = ProviderScope.containerOf(
      tester.element(find.byType(_Home)),
    ).read(appPopupStoreProvider);
    store.shownThisOpen = false;
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsNothing);

    repo.items = [_popup('a', version: 2)];
    store.shownThisOpen = false;
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsOneWidget);
  });

  testWidgets('one per open: the first that isn’t suppressed', (tester) async {
    final repo = _Repo([_popup('a'), _popup('b')]);
    await _pump(
      tester,
      repo,
      prefsValues: {
        AppPopupStore.prefsKey: jsonEncode({'a': '1'}),
      },
    );
    await _check(tester);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://cdn.test/b.png');
    await tester.tap(find.byKey(const Key('appPopupClose')));
    await tester.pumpAndSettle();
    // Already shown this open: no second one.
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsNothing);
  });

  testWidgets('the button closes it and opens the deeplink', (tester) async {
    final repo = _Repo([
      _popup(
        'a',
        action: {
          'type': 'deeplink',
          'value': '/rewards',
          'button_text': 'ดูเลย',
        },
      ),
    ]);
    final env = await _pump(tester, repo);
    await _check(tester);
    await tester.tap(find.byKey(const Key('appPopupButton')));
    await tester.pumpAndSettle();
    expect(env.router.routerDelegate.currentConfiguration.uri.path, '/rewards');
    expect(find.text('rewards page'), findsOneWidget);
  });

  testWidgets('the backdrop counts as ✕', (tester) async {
    final repo = _Repo([_popup('a')]);
    await _pump(tester, repo);
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appPopupImage')), findsNothing);
  });

  testWidgets('an image that won’t load: no pop-up', (tester) async {
    appPopupPrecache = (_, _) async => false;
    final repo = _Repo([_popup('a')]);
    await _pump(tester, repo);
    await _check(tester);
    expect(find.byKey(const Key('appPopupImage')), findsNothing);
  });
}
