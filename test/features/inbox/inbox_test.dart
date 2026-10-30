import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:customer_app/features/inbox/presentation/inbox_controller.dart';
import 'package:customer_app/features/inbox/presentation/inbox_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:typed_data';

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

  var readAll = 0;
  final deleted = <String>[];
  var deletedAll = 0;
  bool fail = false;

  @override
  Future<void> markAllRead({Iterable<String> loadedUnread = const []}) async {
    if (fail) throw Exception('500');
    readAll++;
  }

  @override
  Future<void> delete(String id) async {
    if (fail) throw Exception('500');
    deleted.add(id);
  }

  @override
  Future<void> deleteAll() async {
    if (fail) throw Exception('500');
    deletedAll++;
  }

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
  final repo = _FakeRepo(
    items ?? [_item('a'), _item('b'), _item('c', read: true)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuthController(signedIn),
        ),
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

  testWidgets('mark all read clears every dot in one call', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('inboxMarkAllRead')));
    await tester.pumpAndSettle();
    expect(repo.readAll, 1);
    expect(repo.marked, isEmpty);
    expect(find.byKey(const Key('inboxUnreadDot')), findsNothing);
    expect(find.byKey(const Key('inboxMarkAllRead')), findsNothing);
    expect(find.text('ยังไม่อ่าน'), findsOneWidget);
  });

  testWidgets('mark all read failing keeps the dots and says so', (
    tester,
  ) async {
    final repo = await _pump(tester);
    repo.fail = true;
    await tester.tap(find.byKey(const Key('inboxMarkAllRead')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inboxUnreadDot')), findsNWidgets(2));
    expect(find.text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'), findsOneWidget);
  });

  testWidgets('swiping a message deletes it and drops the badge', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await tester.drag(find.text('Title a'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['a']);
    expect(find.text('Title a'), findsNothing);
    expect(find.text('ยังไม่อ่าน 1'), findsOneWidget);
  });

  testWidgets('a failed delete puts the message back', (tester) async {
    final repo = await _pump(tester);
    repo.fail = true;
    await tester.drag(find.text('Title a'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('ยังไม่อ่าน 2'), findsOneWidget);
    expect(find.text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'), findsOneWidget);
  });

  testWidgets('delete all asks first, then empties the inbox', (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.byKey(const Key('inboxMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxDeleteAll')));
    await tester.pumpAndSettle();
    expect(find.text('ลบข้อความทั้งหมด?'), findsOneWidget);
    expect(find.text('ย้อนกลับไม่ได้'), findsOneWidget);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(repo.deletedAll, 0);
    expect(find.text('Title a'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inboxMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxDeleteAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxDeleteAllYes')));
    await tester.pumpAndSettle();
    expect(repo.deletedAll, 1);
    expect(find.text('ยังไม่มีข้อความ'), findsOneWidget);
    expect(find.byKey(const Key('inboxMenu')), findsNothing);
    expect(find.byKey(const Key('inboxMarkAllRead')), findsNothing);
  });

  testWidgets('a failed delete all keeps every message', (tester) async {
    final repo = await _pump(tester);
    repo.fail = true;
    await tester.tap(find.byKey(const Key('inboxMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxDeleteAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxDeleteAllYes')));
    await tester.pumpAndSettle();
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง'), findsOneWidget);
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

  group('InboxRepository', () {
    late _Adapter adapter;
    late InboxRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = InboxRepository(Dio()..httpClientAdapter = adapter);
    });

    test('read all is one PATCH', () async {
      adapter.answer = (200, {'updated': 2});
      await repo.markAllRead(loadedUnread: ['a']);
      expect(adapter.calls, ['PATCH /api/notifications/read-all']);
    });

    test('a backend without read-all marks the loaded ones instead', () async {
      adapter.answer = (
        404,
        {
          'code': 'SYSTEM_INTERNAL_ERROR',
          'message': 'Cannot PATCH /api/notifications/read-all',
        },
      );
      adapter.then = (200, {'status': 'read'});
      await repo.markAllRead(loadedUnread: ['a', 'b']);
      expect(adapter.calls, [
        'PATCH /api/notifications/read-all',
        'PATCH /api/notifications/a/read',
        'PATCH /api/notifications/b/read',
      ]);
    });

    test('deleting one already gone (inbox 404) counts as deleted', () async {
      adapter.answer = (404, {'error': 'not found'});
      await repo.delete('a');
      expect(adapter.calls, ['DELETE /api/notifications/a']);
    });

    test('a backend without the delete route throws', () async {
      // What prod answers today, before the route ships.
      adapter.answer = (
        404,
        {
          'code': 'SYSTEM_INTERNAL_ERROR',
          'message': 'Cannot DELETE /api/notifications/a',
        },
      );
      await expectLater(repo.delete('a'), throwsA(isA<DioException>()));
    });

    test('delete all is one DELETE', () async {
      adapter.answer = (200, {'deleted': 3});
      await repo.deleteAll();
      expect(adapter.calls, ['DELETE /api/notifications']);
    });
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

/// Answers every request with [answer] (then [then], if set) and records
/// "METHOD path".
class _Adapter implements HttpClientAdapter {
  (int, Object) answer = (200, const {});
  (int, Object)? then;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = calls.isEmpty ? answer : (then ?? answer);
    calls.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
