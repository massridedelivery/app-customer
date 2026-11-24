import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/core/data/api_repository.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/presentation/scheduled_list.dart';
import 'package:customer_app/features/advance_booking/presentation/scheduled_ride_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request by its "METHOD path".
class _Adapter implements HttpClientAdapter {
  _Adapter(this.answers);

  final Map<String, (int, Object)> answers;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    calls.add(key);
    final (status, body) = answers[key] ?? (404, const {'error': 'x'});
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

Map<String, dynamic> _job({
  String id = 'j1',
  String? driverId,
  String? phase,
  int? reschedulesLeft,
  String scheduledAt = '2026-11-22T00:30:00Z',
}) => {
  'id': id,
  'status': 'PENDING',
  // 07:30 in Bangkok on Sunday 22 Nov.
  'scheduled_at': scheduledAt,
  'pickup_address': 'บ้าน',
  'dropoff_address': 'สนามบินสุวรรณภูมิ',
  'fare': 240,
  'advance_booking_fee': 40,
  'payment_method': 'PROMPTPAY',
  'driver_id': ?driverId,
  'advance_phase': ?phase,
  'reschedules_left': ?reschedulesLeft,
  if (driverId != null)
    'driver_info': {
      'full_name': 'สมชาย',
      'vehicle_plate': 'กข 1234',
      'vehicle_model': 'Toyota Altis',
      'vehicle_color': 'สีขาว',
      'vehicle_type_display_name': 'Comfort',
    },
  'advance_policy': {
    'free_cancel_minutes': 60,
    'late_cancel_fee': 60,
    'wait_minutes': 10,
    'min_lead_minutes': 30,
  },
};

Future<_Adapter> _pump(
  WidgetTester tester,
  Widget home, {
  required List<Map<String, dynamic>> jobs,
  Map<String, (int, Object)> answers = const {},
}) async {
  final adapter = _Adapter(answers);
  final dio = Dio(BaseOptions(baseUrl: 'https://test'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiRepositoryProvider.overrideWithValue(ApiRepository(dio)),
        scheduledRidesProvider.overrideWith(
          (ref) async => jobs.map(ScheduledRide.fromJson).toList(),
        ),
        advanceConfigProvider.overrideWith(
          (ref) async => AdvanceConfig.fromJson({
            'enabled': true,
            'min_lead_minutes': 30,
            'max_days': 7,
            'slot_minutes': 5,
          }),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  testWidgets('detail: time, price, policy line and both actions', (
    tester,
  ) async {
    await _pump(tester, const ScheduledRideScreen(jobId: 'j1'), jobs: [_job()]);
    expect(find.textContaining('07:30'), findsWidgets);
    expect(find.byKey(const Key('scheduledRideTicket')), findsOneWidget);
    expect(find.text('07:30 น.'), findsOneWidget);
    expect(find.text('วันอาทิตย์ที่ 22 พฤศจิกายน 2569'), findsOneWidget);
    expect(find.text('ค่าบริการจองล่วงหน้า'), findsOneWidget);
    expect(find.text('฿200'), findsOneWidget); // ride fare = 240 − 40
    expect(find.text('฿240'), findsOneWidget);
    expect(find.text('รวม · พร้อมเพย์'), findsOneWidget);
    expect(
      find.textContaining('หลังจากนั้นเสีย ฿60 ถ้ามีคนขับรับงานแล้ว'),
      findsOneWidget,
    );
    expect(find.textContaining('คนขับรอได้ 10 นาที'), findsOneWidget);
    expect(find.text('รอคนขับ'), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideReschedule')), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideCancel')), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideReport')), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideBanner')), findsNothing);
  });

  testWidgets('still free to cancel: the green box leads with it', (
    tester,
  ) async {
    final at = DateTime.now().toUtc().add(const Duration(days: 2));
    await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'j1'),
      jobs: [_job(scheduledAt: at.toIso8601String(), reschedulesLeft: 3)],
    );
    expect(find.byKey(const Key('scheduledRideFreeCancel')), findsOneWidget);
    expect(find.textContaining('ยกเลิกฟรีถึง'), findsOneWidget);
    expect(
      find.text(
        'หลังจากนั้นเสีย ฿60 ถ้ามีคนขับรับงานแล้ว · คนขับรอได้ 10 นาที · '
        'เลื่อนได้อีก 3 ครั้ง',
      ),
      findsOneWidget,
    );
  });

  testWidgets('driver changed push: the banner', (tester) async {
    await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'j1', driverChanged: true),
      jobs: [_job()],
    );
    expect(
      find.text('คนขับคนเดิมรับงานไม่ได้ กำลังหาคนขับใหม่ให้ · ยกเลิกได้ฟรี'),
      findsOneWidget,
    );
  });

  testWidgets('with a driver: driver card, no reschedule', (tester) async {
    await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'j1'),
      jobs: [_job(driverId: 'd1', phase: 'RESERVED')],
    );
    expect(find.text('สมชาย'), findsOneWidget);
    expect(find.text('Toyota Altis สีขาว · กข 1234'), findsOneWidget);
    expect(find.text('มีคนขับแล้ว'), findsOneWidget);
    expect(find.text('Comfort · ค่าโดยสาร'), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideReschedule')), findsNothing);
  });

  testWidgets('no moves left: no reschedule button', (tester) async {
    await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'j1'),
      jobs: [_job(reschedulesLeft: 0)],
    );
    expect(find.byKey(const Key('scheduledRideReschedule')), findsNothing);
  });

  testWidgets(
    'cancel asks cancel-quote first; free → the sheet, then cancels',
    (tester) async {
      final adapter = await _pump(
        tester,
        const ScheduledRideScreen(jobId: 'j1'),
        jobs: [_job()],
        answers: {
          'GET /api/customer/jobs/scheduled/j1/cancel-quote': (
            200,
            {'is_free': true, 'cancellation_fee': 0, 'reason': 'NO_DRIVER_YET'},
          ),
          'POST /api/customer/jobs/scheduled/j1/cancel': (200, {'ok': true}),
        },
      );
      await tester.tap(find.byKey(const Key('scheduledRideCancel')));
      await tester.pumpAndSettle();
      expect(find.text('ยกเลิกฟรี · ยังไม่มีคนขับรับงาน'), findsOneWidget);
      await tester.tap(find.byKey(const Key('scheduledRideCancelConfirm')));
      await tester.pumpAndSettle();
      expect(adapter.calls, [
        'GET /api/customer/jobs/scheduled/j1/cancel-quote',
        'POST /api/customer/jobs/scheduled/j1/cancel',
      ]);
    },
  );

  testWidgets('cancel with a fee shows the amount and can be kept', (
    tester,
  ) async {
    final adapter = await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'j1'),
      jobs: [_job(driverId: 'd1')],
      answers: {
        'GET /api/customer/jobs/scheduled/j1/cancel-quote': (
          200,
          {'is_free': false, 'cancellation_fee': 60, 'reason': 'LATE_CANCEL'},
        ),
      },
    );
    await tester.tap(find.byKey(const Key('scheduledRideCancel')));
    await tester.pumpAndSettle();
    expect(find.text('ยกเลิกตอนนี้เสีย ฿60'), findsOneWidget);
    expect(find.text('ยกเลิกและเสีย ฿60'), findsOneWidget);
    await tester.tap(find.text('ไม่ยกเลิก'));
    await tester.pumpAndSettle();
    expect(adapter.calls, ['GET /api/customer/jobs/scheduled/j1/cancel-quote']);
  });

  testWidgets('a booking no longer listed says so', (tester) async {
    await _pump(
      tester,
      const ScheduledRideScreen(jobId: 'gone'),
      jobs: [_job()],
    );
    expect(find.byKey(const Key('scheduledRideNotFound')), findsOneWidget);
  });

  testWidgets('bookings list: grouped by day with status chips', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(body: ScheduledBookingsList()),
      jobs: [
        _job(id: 'a'),
        {
          ..._job(id: 'b', driverId: 'd1'),
          // 08:00 Bangkok on Monday 23 Nov.
          'scheduled_at': '2026-11-23T01:00:00Z',
        },
      ],
    );
    expect(find.textContaining('อา. 22 พ.ย.'), findsOneWidget);
    expect(find.textContaining('จ. 23 พ.ย.'), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('รอคนขับ'), findsOneWidget);
    expect(find.text('มีคนขับแล้ว'), findsOneWidget);
    expect(find.text('บ้าน → สนามบินสุวรรณภูมิ'), findsNWidgets(2));
  });

  test('groupScheduledByDay sorts and groups by Bangkok day', () {
    final rides = [
      ScheduledRide.fromJson({
        ..._job(id: 'late'),
        'scheduled_at': '2026-11-23T01:00:00Z',
      }),
      // 23:30 UTC on the 22nd is 06:30 on the 23rd in Bangkok.
      ScheduledRide.fromJson({
        ..._job(id: 'early'),
        'scheduled_at': '2026-11-22T23:30:00Z',
      }),
      ScheduledRide.fromJson(_job(id: 'first')),
      ScheduledRide.fromJson({..._job(id: 'none'), 'scheduled_at': null}),
    ];
    final groups = groupScheduledByDay(rides);
    expect(groups.map((g) => g.rides.map((r) => r.id).toList()).toList(), [
      ['first'],
      ['early', 'late'],
      ['none'],
    ]);
    expect(groups[1].day, DateTime.utc(2026, 11, 23));
    expect(groups.last.day, isNull);
  });

  test('model: reschedule rules, ride fare, driver info', () {
    final free = ScheduledRide.fromJson(_job());
    expect(free.canReschedule, isTrue);
    expect(free.rideFare, 200);
    expect(free.minLeadMinutes, 30);
    expect(free.paymentMethod, 'PROMPTPAY');
    expect(
      ScheduledRide.fromJson(_job(reschedulesLeft: 0)).canReschedule,
      isFalse,
    );
    expect(
      ScheduledRide.fromJson(_job(phase: 'DISPATCHING')).canReschedule,
      isFalse,
    );
    final taken = ScheduledRide.fromJson(_job(driverId: 'd1'));
    expect(taken.canReschedule, isFalse);
    expect(taken.vehicleName, 'Comfort');
    expect(taken.vehicleDescription, 'Toyota Altis สีขาว');
  });
}
