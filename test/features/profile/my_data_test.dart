import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/services/retry_interceptor.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/profile/data/datasources/account_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/my_data.dart';
import 'package:customer_app/features/profile/presentation/screens/my_data_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nothing watches auth in these tests, so the provider may be rebuilt
/// between reads: [logouts] counts across instances.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.logouts);
  final List<int> logouts;

  @override
  AuthState build() => const AuthState(isAuthenticated: true);

  @override
  Future<void> logout() async {
    logouts.add(1);
    state = const AuthState(isAuthenticated: false);
  }
}

/// Serves [export] (or throws [error]) and pages trips from [tripPages].
class _FakeSource implements AccountRemoteDataSource {
  _FakeSource(this.export);

  Map<String, dynamic> export;
  Object? error;
  Object? pageError;
  Completer<void>? pageGate;
  var exportCalls = 0;
  final pageCalls = <String>[];

  @override
  Future<Map<String, dynamic>> exportData() async {
    exportCalls++;
    if (error != null) throw error!;
    return export;
  }

  @override
  Future<Map<String, dynamic>> exportSection(
    String section, {
    required int page,
    int limit = 20,
  }) async {
    pageCalls.add('$section:$page');
    await pageGate?.future;
    if (pageError != null) throw pageError!;
    return {
      'title': 'ประวัติการเดินทาง',
      'items': [_trip('t$page', 'ทริปหน้า $page')],
      'page': page,
      'limit': limit,
      'total': 2,
      'has_more': false,
    };
  }

  @override
  Future<Map<String, dynamic>> requestDeletion(String reason) =>
      throw UnimplementedError();
}

Map<String, dynamic> _trip(String id, String label) => {
  'id': id,
  'status_label': label,
  'pickup_address': 'สยาม',
  'dropoff_address': 'อโศก',
  'stops': [],
  'fare': 120,
  'discount': 0,
  'payment_method': 'CASH',
  'created_at': '2026-10-30T03:00:00Z',
  'driver': {
    'name': 'สมชาย',
    'vehicle_plate': '1กข 1234',
    'vehicle_model': 'Vios',
    'vehicle_color': 'ขาว',
  },
};

Map<String, dynamic> _export() => {
  'format_version': 1,
  'exported_at': '2026-11-02T05:00:00Z',
  'sections': [
    'profile',
    'notification_prefs',
    'future_section',
    'trips',
    'search_history',
  ],
  'profile': {
    'title': 'ข้อมูลส่วนตัว',
    'full_name': 'สมหญิง ใจดี',
    'phone': '0812345678',
    'email': null,
    'date_of_birth': '1990-05-01',
    'avatar_url': null,
    'created_at': '2026-01-15T03:00:00Z',
    'emergency_contact': null,
    'ride_preferences': {},
  },
  'notification_prefs': {
    'title': 'การตั้งค่าการแจ้งเตือน',
    'marketing_opt_in': true,
    'language': 'th',
  },
  'future_section': {'title': 'ส่วนใหม่', 'items': []},
  'trips': {
    'title': 'ประวัติการเดินทาง',
    'items': [_trip('t1', 'เสร็จสิ้น')],
    'page': 1,
    'limit': 1,
    'total': 2,
    'has_more': true,
  },
  'search_history': {
    'title': 'ประวัติการค้นหา',
    'items': [],
    'page': 1,
    'limit': 20,
    'total': 0,
    'has_more': false,
  },
};

Response<dynamic> _response(
  int status, [
  Object? body,
  Map<String, List<String>>? headers,
]) => Response(
  requestOptions: RequestOptions(path: '/api/customer/export'),
  statusCode: status,
  data: body,
  headers: Headers.fromMap(headers ?? {}),
);

Future<(_FakeSource, List<int>)> _pump(
  WidgetTester tester, {
  _FakeSource? source,
  bool settle = true,
}) async {
  final src = source ?? _FakeSource(_export());
  final logouts = <int>[];
  // Tall enough that every section is built.
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(logouts)),
        accountRemoteDataSourceProvider.overrideWithValue(src),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: const MyDataScreen(),
      ),
    ),
  );
  if (settle) {
    await tester.pump();
    await tester.pump();
  }
  return (src, logouts);
}

Future<void> _expand(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key('myDataSection_$key')));
  await tester.tap(find.byKey(Key('myDataSection_$key')));
  await tester.pumpAndSettle();
}

void main() {
  group('MyData', () {
    test('keeps the server order and skips sections it does not know', () {
      final d = MyData.fromJson(_export());
      expect(d.sections.map((s) => s.key), [
        'profile',
        'notification_prefs',
        'trips',
        'search_history',
      ]);
      final trips = d.section('trips')!;
      expect(trips.title, 'ประวัติการเดินทาง');
      expect(trips.total, 2);
      expect(trips.hasMore, isTrue);
    });

    test('a loaded page is appended and shared with the rest', () {
      final d = MyData.fromJson(_export());
      final more = d.section('trips')!.append({
        'items': [_trip('t2', 'ยกเลิก')],
        'page': 2,
        'limit': 1,
        'total': 2,
        'has_more': false,
      });
      expect(more.items.map((i) => i['id']), ['t1', 't2']);
      expect(more.page, 2);
      expect(more.hasMore, isFalse);

      final json = d.withSection(more).toJson();
      final trips = json['trips'] as Map<String, dynamic>;
      expect((trips['items'] as List).length, 2);
      expect(trips['has_more'], isFalse);
      // Untouched: the format version and the section the app doesn't show.
      expect(json['format_version'], 1);
      expect(json['future_section'], isNotNull);
    });
  });

  group('dataExportError', () {
    test('404 means the account is gone', () {
      expect(
        dataExportError(_response(404, {'error': 'account not found'})),
        isA<DataExportAccountGone>(),
      );
    });

    test('429 carries the message and the wait', () {
      final e = dataExportError(
        _response(429, {
          'error': 'ขอข้อมูลบ่อยเกินไป',
          'code': 'DATA_EXPORT_RATE_LIMITED',
          'retry_after': 42,
        }),
      );
      expect(e, isA<DataExportRateLimited>());
      e as DataExportRateLimited;
      expect(e.message, 'ขอข้อมูลบ่อยเกินไป');
      expect(e.retryAfter, const Duration(seconds: 42));
    });

    test('429 without a body falls back to the Retry-After header', () {
      final e =
          dataExportError(
                _response(429, 'Too Many Requests', {
                  'retry-after': ['17'],
                }),
              )
              as DataExportRateLimited;
      expect(e.message, isNull);
      expect(e.retryAfter, const Duration(seconds: 17));
    });

    test('a 404 for a missing route never means the account is gone', () {
      // What a backend without the export route answers (Fiber's default).
      expect(
        dataExportError(
          _response(404, {
            'code': 'SYSTEM_INTERNAL_ERROR',
            'message': 'Cannot GET /api/customer/export',
          }),
        ),
        isA<DataExportFailed>(),
      );
      expect(
        dataExportError(_response(404, 'Cannot GET /api/customer/export')),
        isA<DataExportFailed>(),
      );
    });

    test('5xx and no response are a plain failure', () {
      expect(dataExportError(_response(500)), isA<DataExportFailed>());
      expect(dataExportError(null), isA<DataExportFailed>());
    });
  });

  group('RetryInterceptor', () {
    Future<(int, int?)> run({required bool optOut}) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _CountingAdapter(429);
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(RetryInterceptor(dio));
      int? status;
      try {
        await dio.get(
          '/x',
          options: Options(
            extra: {if (optOut) RetryInterceptor.noRetryOn429: true},
          ),
        );
      } on DioException catch (e) {
        status = e.response?.statusCode;
      }
      return (adapter.calls, status);
    }

    test('a request that opts out gets its 429 straight back', () async {
      final (calls, status) = await run(optOut: true);
      expect(calls, 1);
      expect(status, 429);
    });

    test('other GETs still retry a 429', () async {
      final (calls, _) = await run(optOut: false);
      expect(calls, 4);
    });
  });

  group('MyDataScreen', () {
    testWidgets('shows the sections in order, with totals and empty states', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('สมหญิง ใจดี'), findsWidgets);
      expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget);
      expect(find.text('การตั้งค่าการแจ้งเตือน'), findsOneWidget);
      expect(find.text('ประวัติการเดินทาง (2)'), findsOneWidget);
      expect(find.text('ประวัติการค้นหา (0)'), findsOneWidget);
      expect(find.text('ส่วนใหม่'), findsNothing);
      // Profile is open; a null email hides its row.
      expect(find.text('0812345678'), findsWidgets);
      expect(find.text('อีเมล'), findsNothing);
      expect(find.text('1 พ.ค. 2533'), findsOneWidget);
      expect(find.text('เปิด'), findsOneWidget);
      expect(find.textContaining('ข้อมูล ณ'), findsOneWidget);

      await _expand(tester, 'search_history');
      expect(find.text('ไม่มีข้อมูล'), findsOneWidget);
    });

    testWidgets('ดูเพิ่มเติม appends the next page', (tester) async {
      final (src, _) = await _pump(tester);
      await _expand(tester, 'trips');
      expect(find.text('เสร็จสิ้น'), findsOneWidget);
      expect(find.text('สมชาย · 1กข 1234 · Vios ขาว'), findsOneWidget);

      src.pageGate = Completer();
      await tester.ensureVisible(find.byKey(const Key('myDataMore_trips')));
      await tester.tap(find.byKey(const Key('myDataMore_trips')));
      await tester.pump();
      expect(find.byKey(const Key('myDataMore_trips')), findsNothing);

      src.pageGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(src.pageCalls, ['trips:2']);
      expect(find.text('เสร็จสิ้น'), findsOneWidget);
      expect(find.text('ทริปหน้า 2'), findsOneWidget);
      expect(find.byKey(const Key('myDataMore_trips')), findsNothing);
    });

    testWidgets('a failed page keeps what is shown and says so', (
      tester,
    ) async {
      final (src, _) = await _pump(tester);
      await _expand(tester, 'trips');
      src.pageError = const DataExportFailed();

      await tester.ensureVisible(find.byKey(const Key('myDataMore_trips')));
      await tester.tap(find.byKey(const Key('myDataMore_trips')));
      await tester.pump();
      await tester.pump();

      expect(find.text('เสร็จสิ้น'), findsOneWidget);
      expect(find.text('ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่'), findsOneWidget);
      expect(find.byKey(const Key('myDataMore_trips')), findsOneWidget);
    });

    testWidgets('a network error offers a retry that reloads', (tester) async {
      final src = _FakeSource(_export())..error = const DataExportFailed();
      await _pump(tester, source: src);

      expect(find.text('ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่'), findsOneWidget);
      src.error = null;
      await tester.tap(find.byKey(const Key('myDataRetry')));
      await tester.pump();
      await tester.pump();

      expect(src.exportCalls, 2);
      expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget);
    });

    testWidgets('429 shows the server message and waits before retrying', (
      tester,
    ) async {
      final src = _FakeSource(_export())
        ..error = const DataExportRateLimited(
          'ขอข้อมูลบ่อยเกินไป',
          Duration(seconds: 3),
        );
      await _pump(tester, source: src);

      expect(find.text('ขอข้อมูลบ่อยเกินไป'), findsOneWidget);
      expect(find.text('ลองใหม่ได้ใน 3 วินาที'), findsOneWidget);
      FilledButton button() =>
          tester.widget(find.byKey(const Key('myDataRetry')));
      expect(button().onPressed, isNull);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(button().onPressed, isNotNull);
    });

    testWidgets('404 says the account is gone, then signs out', (tester) async {
      final src = _FakeSource(_export())..error = const DataExportAccountGone();
      final (_, logouts) = await _pump(tester, source: src);
      await tester.pump();

      expect(find.text('ไม่พบบัญชีนี้แล้ว'), findsOneWidget);
      expect(logouts, isEmpty);
      await tester.tap(find.byKey(const Key('myDataAccountGoneOk')));
      await tester.pump();
      expect(logouts, hasLength(1));
    });
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.status);
  final int status;
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode({'error': 'slow down'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'retry-after': ['0'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
