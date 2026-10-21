import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:customer_app/features/inbox/presentation/inbox_controller.dart';
import 'package:customer_app/features/inbox/presentation/inbox_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.signedIn);
  final bool signedIn;

  @override
  AuthState build() => AuthState(isAuthenticated: signedIn);
}

/// Serves a fixed inbox and records which ids were marked read.
class _FakeRepo extends InboxRepository {
  _FakeRepo(this.items) : super(Dio());
  final List<InboxItem> items;
  final marked = <String>[];

  final offsets = <int>[];

  @override
  Future<({List<InboxItem> items, int unread})> fetch({
    int limit = 20,
    int offset = 0,
  }) async {
    offsets.add(offset);
    return (
      items: items.skip(offset).take(limit).toList(),
      unread: items.where((i) => !i.isRead).length,
    );
  }

  @override
  Future<void> markRead(String id) async => marked.add(id);

  final optIns = <bool>[];
  bool failPrefs = false;

  @override
  Future<void> setMarketingOptIn(bool optIn) async {
    if (failPrefs) throw Exception('500');
    optIns.add(optIn);
  }
}

InboxItem _item(String id, {bool read = false}) => InboxItem(
  id: id,
  title: 'Title $id',
  body: 'Body $id',
  data: const {'screen': 'promo'},
  createdAt: DateTime.now(),
  readAt: read ? DateTime.now() : null,
);

Future<_FakeRepo> _pump(
  WidgetTester tester, {
  bool signedIn = true,
  List<InboxItem>? items,
}) async {
  final repo = _FakeRepo(items ?? [_item('a'), _item('b'), _item('c', read: true)]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(signedIn)),
        inboxRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: const InboxScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('InboxItem.fromJson', () {
    test('parses the BE shape', () {
      final i = InboxItem.fromJson({
        'id': 'n1',
        'title': 'ลด ฿100',
        'body': 'ใช้โค้ด DIS100',
        'data': {'deeplink': '/promos/p1', 'screen': 'promo', 'n': 3},
        'created_at': '2026-10-20T03:00:00Z',
        'read_at': null,
      });
      expect(i.id, 'n1');
      expect(i.isRead, isFalse);
      expect(i.screen, 'promo');
      expect(i.deeplink, '/promos/p1');
      expect(i.data['n'], '3');
      expect(i.createdAt.isUtc, isFalse);
    });

    test('home / bad links open nothing', () {
      InboxItem withLink(String? l) => InboxItem.fromJson({
        'id': 'x',
        'data': {'deeplink': ?l},
        'read_at': '2026-10-20T03:00:00Z',
      });
      expect(withLink('/main').deeplink, isNull);
      expect(withLink('/').deeplink, isNull);
      expect(withLink('https://evil').deeplink, isNull);
      expect(withLink(null).deeplink, isNull);
      expect(withLink('/main').isRead, isTrue);
    });
  });

  testWidgets('guests see the login card', (tester) async {
    await _pump(tester, signedIn: false);
    expect(find.byType(ListView), findsNothing);
    expect(find.byKey(const Key('inboxMarkAllRead')), findsNothing);
  });

  testWidgets('lists items; unread ones carry a dot', (tester) async {
    await _pump(tester);
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Title c'), findsOneWidget);
    expect(find.byKey(const Key('inboxUnreadDot')), findsNWidgets(2));
    expect(find.text('ยังไม่อ่าน 2'), findsOneWidget);
  });

  testWidgets('unread filter hides read items', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('ยังไม่อ่าน 2'));
    await tester.pumpAndSettle();
    expect(find.text('Title c'), findsNothing);
    expect(find.text('Title a'), findsOneWidget);
  });

  testWidgets('tapping an item marks it read', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(repo.marked, ['a']);
    expect(find.byKey(const Key('inboxUnreadDot')), findsOneWidget);
  });

  testWidgets('mark all read clears every dot', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('inboxMarkAllRead')));
    await tester.pumpAndSettle();
    expect(repo.marked.toSet(), {'a', 'b'});
    expect(find.byKey(const Key('inboxUnreadDot')), findsNothing);
    expect(find.byKey(const Key('inboxMarkAllRead')), findsNothing);
  });

  testWidgets('empty inbox shows the empty message', (tester) async {
    await _pump(tester, items: const []);
    expect(find.text('ยังไม่มีข้อความ'), findsOneWidget);
  });

  test('badge provider counts unread', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(true)),
        inboxRepositoryProvider.overrideWithValue(
          _FakeRepo([_item('a'), _item('b', read: true)]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(inboxControllerProvider.future);
    expect(container.read(inboxUnreadProvider), 1);
  });

  testWidgets('scrolling to the end loads the next page by offset', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      items: [for (var i = 0; i < 45; i++) _item('m$i')],
    );
    expect(repo.offsets, [0]);
    expect(find.byKey(const Key('inboxLoadingMore')), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(repo.offsets, [0, 20, 40]);
    expect(find.text('Title m44'), findsOneWidget);
  });

  group('marketing opt-in', () {
    test('defaults on, saves via PATCH prefs, reverts on failure', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeRepo(const []);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          inboxRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(marketingOptInProvider), isTrue);

      await container.read(marketingOptInProvider.notifier).set(false);
      expect(repo.optIns, [false]);
      expect(container.read(marketingOptInProvider), isFalse);
      expect(container.read(appStorageProvider).marketingOptIn, isFalse);

      repo.failPrefs = true;
      await expectLater(
        container.read(marketingOptInProvider.notifier).set(true),
        throwsA(anything),
      );
      expect(container.read(marketingOptInProvider), isFalse);
    });
  });
}
