import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:customer_app/features/support/domain/low_rating_report.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/features/support/presentation/report_issue_screen.dart';
import 'package:customer_app/features/support/presentation/support_ticket_detail_screen.dart';
import 'package:customer_app/features/support/presentation/support_tickets_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ─── HTTP fakes ──────────────────────────────────────────────────────────────

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions o) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _Api implements ApiService {
  _Api(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _ticketJson({
  String id = 't-1',
  String status = 'open',
  List<Map<String, dynamic>> replies = const [],
  String? resolution,
  num? refund,
}) => {
  'id': id,
  'ticket_no': 'T-0042',
  'category': 'driver_behavior',
  'service': 'ride',
  'ref_id': 'job-12345678abc',
  'description': 'ไรเดอร์พูดจาไม่สุภาพ',
  'status': status,
  'resolution': ?resolution,
  'refund_amount': ?refund,
  'attachments': [
    {'file_key': 'support/u/1.jpg', 'url': 'https://s3.test/1.jpg'},
  ],
  'replies': replies,
  'unread': true,
  'created_at': '2026-11-05T03:00:00Z',
};

// ─── Repository fake for widgets ─────────────────────────────────────────────

class _FakeRepo implements SupportRepository {
  final created = <NewSupportTicket>[];
  final replies = <(String, String)>[];
  Object? createError;
  SupportTicket? detail;
  List<SupportTicket> tickets = const [];

  @override
  Future<SupportTicket> create(
    NewSupportTicket ticket, {
    required String idempotencyKey,
  }) async {
    created.add(ticket);
    if (createError != null) throw createError!;
    return SupportTicket.fromJson(_ticketJson(id: 'new-1'));
  }

  @override
  Future<List<SupportTicket>> list({int page = 1, int limit = 20}) async =>
      tickets;

  @override
  Future<SupportTicket> get(String id) async =>
      detail ?? SupportTicket.fromJson(_ticketJson(id: id));

  @override
  Future<void> reply(String id, String message) async =>
      replies.add((id, message));

  @override
  Future<String> uploadPhoto(Uint8List jpeg) async => 'support/u/x.jpg';
}

/// Report form (or [initial]) inside a router that also knows the ticket
/// pages, in Thai.
Future<GoRouter> _pumpApp(
  WidgetTester tester,
  _FakeRepo repo, {
  String initial = '/report',
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/report',
        builder: (_, _) => const ReportIssueScreen(
          service: SupportService.ride,
          refId: 'job-12345678abc',
          source: SupportSource.tripDetail,
        ),
      ),
      GoRoute(
        path: '/support/tickets',
        builder: (_, _) => const SupportTicketsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                SupportTicketDetailScreen(ticketId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/support/report',
        builder: (_, _) => const ReportIssueScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supportRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('SupportRepository', () {
    late _Adapter adapter;
    late SupportRepository repo;
    late _Adapter storage;

    void setUpRepo(ResponseBody Function(RequestOptions o) handler) {
      adapter = _Adapter(handler);
      storage = _Adapter((_) => ResponseBody.fromString('', 200));
      repo = SupportRepository(
        _Api(
          Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
        ),
        storageDio: Dio()..httpClientAdapter = storage,
      );
    }

    test(
      'files a report with its order, photos and one idempotency key',
      () async {
        setUpRepo((_) => _json({'ticket': _ticketJson()}, 201));
        final t = await repo.create(
          const NewSupportTicket(
            category: SupportCategory.safety,
            description: 'ขับเร็วมาก',
            source: SupportSource.tripDetail,
            service: SupportService.ride,
            refId: 'job-1',
            attachments: ['support/u/1.jpg'],
          ),
          idempotencyKey: 'key-1',
        );
        final req = adapter.requests.single;
        expect(req.method, 'POST');
        expect(req.path, '/api/customer/support/tickets');
        expect(req.headers['Idempotency-Key'], 'key-1');
        expect(req.data, {
          'category': 'safety',
          'description': 'ขับเร็วมาก',
          'source': 'trip_detail',
          'service': 'ride',
          'ref_id': 'job-1',
          'attachments': ['support/u/1.jpg'],
        });
        expect(t.id, 't-1');
        expect(t.displayNo, 'T-0042');
        expect(t.status, SupportStatus.open);
        expect(t.attachments.single.url, 'https://s3.test/1.jpg');
      },
    );

    test('lists reports from {tickets: [...]}', () async {
      setUpRepo(
        (_) => _json({
          'tickets': [
            _ticketJson(),
            _ticketJson(id: 't-2', status: 'resolved'),
          ],
          'total': 2,
        }),
      );
      final list = await repo.list();
      expect(list.map((t) => t.id), ['t-1', 't-2']);
      expect(list[1].status, SupportStatus.resolved);
      expect(adapter.requests.single.queryParameters, {'page': 1, 'limit': 20});
    });

    test(
      'a duplicate report surfaces TICKET_ALREADY_OPEN with the open one',
      () async {
        setUpRepo(
          (_) => _json({
            'code': 'TICKET_ALREADY_OPEN',
            'error': 'มีเรื่องนี้อยู่แล้ว',
            'ticket_id': 't-9',
          }, 409),
        );
        await expectLater(
          repo.create(
            const NewSupportTicket(
              category: SupportCategory.other,
              description: 'xxxxxxxxxxxx',
              source: SupportSource.profile,
            ),
            idempotencyKey: 'k',
          ),
          throwsA(
            isA<ApiError>()
                .having((e) => e.code, 'code', 'TICKET_ALREADY_OPEN')
                .having((e) => e.extra['ticket_id'], 'ticket_id', 't-9'),
          ),
        );
      },
    );

    test('photos go up under the support category', () async {
      setUpRepo((o) {
        if (o.path == '/api/media/upload-url') {
          return _json({
            'upload_url': 'https://s3.test/put',
            'file_key': 'support/u/2.jpg',
            'max_bytes': 2097152,
          });
        }
        return _json({'confirmed': true});
      });
      final key = await repo.uploadPhoto(Uint8List.fromList([1, 2, 3]));
      expect(key, 'support/u/2.jpg');
      expect(adapter.requests.first.queryParameters, {
        'category': 'support',
        'content_type': 'image/jpeg',
      });
      expect(storage.requests.single.method, 'PUT');
      expect(adapter.requests.last.path, '/api/media/confirm');
      expect(adapter.requests.last.data, {'file_key': 'support/u/2.jpg'});
    });

    test('replies come oldest first, admin or customer', () {
      final t = SupportTicket.fromJson(
        _ticketJson(
          replies: [
            {
              'id': 'r2',
              'from': 'customer',
              'message': 'เพิ่มเติม',
              'created_at': '2026-11-05T05:00:00Z',
            },
            {
              'id': 'r1',
              'from': 'admin',
              'message': 'รับเรื่องแล้ว',
              'created_at': '2026-11-05T04:00:00Z',
            },
          ],
        ),
      );
      expect(t.replies.map((r) => r.id), ['r1', 'r2']);
      expect(t.replies.first.fromAdmin, isTrue);
      expect(t.replies.last.fromAdmin, isFalse);
    });
  });

  group('low ride rating → report', () {
    NewSupportTicket? report(int rating, List<String> tags, [String c = '']) =>
        lowRatingReport(
          jobId: 'job-1',
          rating: rating,
          tags: tags,
          comment: c,
          heading: (s) => 'รายงานจากการให้คะแนน $s ดาว',
          tagLabel: (t) => t,
        );

    test('4–5 stars or no "what went wrong" tag files nothing', () {
      expect(report(4, ['ไม่สุภาพ']), isNull);
      expect(report(2, ['สุภาพ']), isNull);
      expect(report(2, []), isNull);
    });

    test('takes the most serious topic and keeps the comment', () {
      final r = report(1, ['มาช้า', 'ขับขี่อันตราย'], ' ขับปาดซ้ายขวา ')!;
      expect(r.category, SupportCategory.safety);
      expect(r.source, SupportSource.rating);
      expect(r.service, SupportService.ride);
      expect(r.refId, 'job-1');
      expect(r.rating, 1);
      expect(r.tags, ['มาช้า', 'ขับขี่อันตราย']);
      expect(
        r.description,
        'รายงานจากการให้คะแนน 1 ดาว: มาช้า, ขับขี่อันตราย\nขับปาดซ้ายขวา',
      );
      expect(
        report(3, ['เก็บเงินเกิน', 'ไม่สุภาพ'])!.category,
        SupportCategory.driverBehavior,
      );
      expect(report(3, ['เส้นทางอ้อม'])!.category, SupportCategory.farePayment);
    });
  });

  group('report form', () {
    testWidgets('asks for a topic, then enough detail, then sends', (
      tester,
    ) async {
      final repo = _FakeRepo();
      final router = await _pumpApp(tester, repo);

      expect(find.text('เรียกรถ · #JOB-1234'), findsOneWidget);

      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pump();
      expect(find.text('กรุณาเลือกเรื่องที่ต้องการแจ้ง'), findsOneWidget);
      expect(repo.created, isEmpty);

      await tester.tap(find.byKey(const Key('supportTopic_safety')));
      await tester.pump();
      // Safety points to SOS for anything happening right now.
      expect(find.byKey(const Key('supportSafetyNote')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('supportDetail')), 'สั้น');
      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pump();
      expect(
        find.text('กรุณาเล่ารายละเอียดอย่างน้อย 10 ตัวอักษร'),
        findsOneWidget,
      );
      expect(repo.created, isEmpty);

      await tester.enterText(
        find.byKey(const Key('supportDetail')),
        'ไรเดอร์ขับเร็วและฝ่าไฟแดงหลายครั้ง',
      );
      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pumpAndSettle();

      final sent = repo.created.single;
      expect(sent.category, SupportCategory.safety);
      expect(sent.service, SupportService.ride);
      expect(sent.refId, 'job-12345678abc');
      expect(sent.source, SupportSource.tripDetail);
      expect(sent.description, 'ไรเดอร์ขับเร็วและฝ่าไฟแดงหลายครั้ง');
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/support/tickets/new-1',
      );
    });

    testWidgets('an already open report opens that one', (tester) async {
      final repo = _FakeRepo()
        ..createError = const ApiError(
          message: 'มีเรื่องนี้อยู่แล้ว',
          code: 'TICKET_ALREADY_OPEN',
          statusCode: 409,
          extra: {'ticket_id': 't-9'},
        );
      final router = await _pumpApp(tester, repo);
      await tester.tap(find.byKey(const Key('supportTopic_driver_behavior')));
      await tester.enterText(
        find.byKey(const Key('supportDetail')),
        'ไรเดอร์พูดจาไม่สุภาพมาก',
      );
      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/support/tickets/t-9',
      );
    });

    testWidgets('a failed send stays on the form with the message', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..createError = const ApiError(message: 'ระบบขัดข้อง', statusCode: 500);
      final router = await _pumpApp(tester, repo);
      await tester.tap(find.byKey(const Key('supportTopic_other')));
      await tester.enterText(
        find.byKey(const Key('supportDetail')),
        'มีปัญหาอื่นๆ ที่อยากแจ้ง',
      );
      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pumpAndSettle();
      expect(find.text('ระบบขัดข้อง'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/report');
    });
  });

  group('my reports', () {
    testWidgets('lists reports with status and the new-reply badge', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..tickets = [SupportTicket.fromJson(_ticketJson())];
      await _pumpApp(tester, repo, initial: '/support/tickets');
      expect(find.text('พฤติกรรมไรเดอร์ไม่เหมาะสม'), findsOneWidget);
      expect(find.text('รอดำเนินการ'), findsOneWidget);
      expect(find.byKey(const Key('supportTicketUnread')), findsOneWidget);
    });

    testWidgets('empty list says so', (tester) async {
      await _pumpApp(tester, _FakeRepo(), initial: '/support/tickets');
      expect(find.byKey(const Key('supportTicketsEmpty')), findsOneWidget);
    });

    testWidgets('an open report shows the conversation and takes a reply', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..detail = SupportTicket.fromJson(
          _ticketJson(
            status: 'in_progress',
            replies: [
              {
                'id': 'r1',
                'from': 'admin',
                'message': 'ขอเวลาตรวจสอบ 1 วันนะคะ',
                'created_at': '2026-11-05T04:00:00Z',
              },
            ],
          ),
        );
      await _pumpApp(tester, repo, initial: '/support/tickets/t-1');
      expect(find.text('เรื่องที่แจ้ง #T-0042'), findsOneWidget);
      expect(find.text('ไรเดอร์พูดจาไม่สุภาพ'), findsOneWidget);
      expect(find.text('ขอเวลาตรวจสอบ 1 วันนะคะ'), findsOneWidget);
      expect(find.text('กำลังดำเนินการ'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('supportReplyField')),
        'เกิดเวลา 14:00 น.',
      );
      await tester.tap(find.byKey(const Key('supportReplySend')));
      await tester.pumpAndSettle();
      expect(repo.replies.single, ('t-1', 'เกิดเวลา 14:00 น.'));
    });

    testWidgets('a resolved report shows the outcome and no reply box', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..detail = SupportTicket.fromJson(
          _ticketJson(
            status: 'resolved',
            resolution: 'ตักเตือนไรเดอร์แล้ว',
            refund: 40,
          ),
        );
      await _pumpApp(tester, repo, initial: '/support/tickets/t-1');
      expect(find.byKey(const Key('supportOutcome')), findsOneWidget);
      expect(find.text('ตักเตือนไรเดอร์แล้ว'), findsOneWidget);
      expect(find.text('คืนเงิน ฿40'), findsOneWidget);
      expect(find.byKey(const Key('supportReplyField')), findsNothing);
      expect(find.byKey(const Key('supportClosedNote')), findsOneWidget);
    });
  });
}
