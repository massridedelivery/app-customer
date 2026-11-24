import 'package:customer_app/features/advance_booking/domain/advance_config.dart';
import 'package:customer_app/features/advance_booking/domain/advance_format.dart';
import 'package:customer_app/features/advance_booking/domain/advance_refusal.dart';
import 'package:customer_app/features/advance_booking/domain/advance_slots.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_booking_controller.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_confirm_screen.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_time_sheet.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio(int status, Object? body) {
  final req = RequestOptions(path: '/api/customer/jobs/schedule');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  // Saturday 21 Nov 2026, 13:02 in Bangkok.
  final now = DateTime.utc(2026, 11, 21, 6, 2);

  group('AdvanceSlots', () {
    test('earliest is now + lead rounded up to the slot', () {
      final s = AdvanceSlots(
        now: now,
        minLeadMinutes: 30,
        maxDays: 7,
        slotMinutes: 5,
      );
      // 13:02 + 30 = 13:32 → 13:35 Bangkok.
      expect(s.earliest, DateTime.utc(2026, 11, 21, 6, 35));
      expect(AdvanceSlots.toBangkok(s.earliest).hour, 13);
    });

    test('an exact slot is not pushed to the next one', () {
      expect(
        AdvanceSlots.earliestSlot(DateTime.utc(2026, 11, 21, 6, 0), 30, 5),
        DateTime.utc(2026, 11, 21, 6, 30),
      );
    });

    test('latest is now + max days rounded down; days span both ends', () {
      final s = AdvanceSlots(
        now: now,
        minLeadMinutes: 30,
        maxDays: 7,
        slotMinutes: 15,
      );
      expect(s.latest, DateTime.utc(2026, 11, 28, 6, 0));
      expect(s.days.first, DateTime.utc(2026, 11, 21));
      expect(s.days.last, DateTime.utc(2026, 11, 28));
      expect(s.days, hasLength(8));
      expect(s.minutes, [0, 15, 30, 45]);
    });

    test('hours before the earliest slot today are not bookable', () {
      final s = AdvanceSlots(
        now: now,
        minLeadMinutes: 30,
        maxDays: 7,
        slotMinutes: 5,
      );
      final today = DateTime.utc(2026, 11, 21);
      expect(s.hourHasSlot(today, 12), isFalse);
      expect(s.hourHasSlot(today, 13), isTrue);
      expect(s.isBookable(s.at(today, 13, 30)), isFalse);
      expect(s.isBookable(s.at(today, 13, 35)), isTrue);
      // Tomorrow early morning is fine.
      expect(s.hourHasSlot(DateTime.utc(2026, 11, 22), 6), isTrue);
    });

    test('clamp snaps into range and onto a slot', () {
      final s = AdvanceSlots(
        now: now,
        minLeadMinutes: 30,
        maxDays: 7,
        slotMinutes: 5,
      );
      expect(s.clamp(now), s.earliest);
      expect(s.clamp(now.add(const Duration(days: 30))), s.latest);
      expect(
        s.clamp(DateTime.utc(2026, 11, 22, 0, 33)),
        DateTime.utc(2026, 11, 22, 0, 30),
      );
    });

    test('a vehicle with a longer lead has its own earliest slot', () {
      final s = AdvanceSlots(
        now: now,
        minLeadMinutes: 30,
        maxDays: 7,
        slotMinutes: 5,
      );
      // 13:02 + 120 = 15:02 → 15:05.
      expect(s.earliestFor(now, 120), DateTime.utc(2026, 11, 21, 8, 5));
    });

    test('Bangkok wall clock round-trips', () {
      final wall = DateTime.utc(2026, 11, 22, 6, 30);
      expect(AdvanceSlots.toBangkok(AdvanceSlots.fromBangkok(wall)), wall);
    });
  });

  group('AdvanceFormat', () {
    const fmt = AdvanceFormat('th');
    test('relative day, weekday and clock in Bangkok time', () {
      expect(
        fmt.relativeDay(DateTime.utc(2026, 11, 21, 10), now: now),
        'วันนี้',
      );
      // 23:30 UTC on the 21st is 06:30 on Sunday the 22nd in Bangkok.
      final tomorrow = DateTime.utc(2026, 11, 21, 23, 30);
      expect(fmt.relativeDay(tomorrow, now: now), 'อา. 22 พ.ย.');
      expect(fmt.clock(tomorrow), '06:30');
      expect(fmt.day(DateTime.utc(2026, 11, 22)), 'อา. 22 พ.ย.');
      expect(fmt.dayHeading(tomorrow, now: now), 'อา. 22 พ.ย.');
      expect(
        fmt.dayHeading(DateTime.utc(2026, 11, 21, 10), now: now),
        'วันนี้ · ส. 21 พ.ย.',
      );
      expect(
        fmt.when(DateTime.utc(2026, 11, 23, 1), now: now),
        'จ. 23 พ.ย. 08:00',
      );
    });
  });

  group('AdvanceRefusal', () {
    test('maps each 422 code', () {
      const codes = {
        'ADVANCE_DISABLED': AdvanceRefusalKind.disabled,
        'VEHICLE_NOT_BOOKABLE': AdvanceRefusalKind.vehicleNotBookable,
        'TOO_SOON': AdvanceRefusalKind.tooSoon,
        'TOO_FAR': AdvanceRefusalKind.tooFar,
        'TOO_MANY_BOOKINGS': AdvanceRefusalKind.tooManyBookings,
        'CASH_NOT_ALLOWED': AdvanceRefusalKind.cashNotAllowed,
        'OUTSTANDING_FEES': AdvanceRefusalKind.outstandingFees,
        'FLIGHT_NUMBER_INVALID': AdvanceRefusalKind.flightNumberInvalid,
        'CANNOT_RESCHEDULE': AdvanceRefusalKind.cannotReschedule,
        'TOO_MANY_RESCHEDULES': AdvanceRefusalKind.tooManyReschedules,
        'SOMETHING_NEW': AdvanceRefusalKind.unknown,
      };
      codes.forEach((code, kind) {
        final r = AdvanceRefusal.from(
          _dio(422, {'code': code, 'error': 'english text'}),
        );
        expect(r?.kind, kind, reason: code);
      });
    });

    test('ADVANCE_DISABLED carries the admin dialog', () {
      final r = AdvanceRefusal.from(
        _dio(422, {
          'code': 'ADVANCE_DISABLED',
          'error': 'off',
          'title': 'ปิดชั่วคราว',
          'message': 'เปิดเร็ว ๆ นี้',
        }),
      )!;
      expect(r.title, 'ปิดชั่วคราว');
      expect(r.message, 'เปิดเร็ว ๆ นี้');
    });

    test('helpers and non-refusals', () {
      expect(
        AdvanceRefusal.from(_dio(422, {'code': 'TOO_SOON'}))!.needsNewTime,
        isTrue,
      );
      expect(
        AdvanceRefusal.from(
          _dio(422, {'code': 'OUTSTANDING_FEES'}),
        )!.needsInAppPayment,
        isTrue,
      );
      expect(AdvanceRefusal.from(_dio(500, {'code': 'TOO_SOON'})), isNull);
      expect(AdvanceRefusal.from(_dio(422, {'error': 'no code'})), isNull);
      expect(AdvanceRefusal.from(Exception('x')), isNull);
    });
  });

  test('looksLikeAirport', () {
    expect(looksLikeAirport('ท่าอากาศยานสุวรรณภูมิ'), isTrue);
    expect(looksLikeAirport('สนามบินดอนเมือง อาคาร 1'), isTrue);
    expect(looksLikeAirport('Suvarnabhumi Airport (BKK)'), isTrue);
    expect(looksLikeAirport('Don Mueang International'), isTrue);
    expect(looksLikeAirport('คอนโดลุมพินี พระราม 9'), isFalse);
    expect(looksLikeAirport(null), isFalse);
  });

  group('parsing', () {
    test('config with its vehicle types; parcel types left out of rides', () {
      final c = AdvanceConfig.fromJson({
        'enabled': true,
        'closed_title': 't',
        'closed_message': 'm',
        'min_lead_minutes': 30,
        'max_days': 7,
        'slot_minutes': 5,
        'free_cancel_minutes': 60,
        'wait_minutes': 10,
        'cash_allowed': false,
        'max_reschedules': 3,
        'airport_wait_minutes': 45,
        'vehicle_types': [
          {
            'vehicle_type_id': 'eco',
            'display_name': 'Economy',
            'vehicle_kind': 'car',
            'advance_booking_fee': 40,
            'min_lead_minutes': 60,
            'late_cancel_fee': 60,
            'search_starts_minutes_before': 60,
          },
          {
            'vehicle_type_id': 'bike',
            'display_name': 'ส่งของ',
            'vehicle_kind': 'motorcycle',
            'vehicle_class': 'messenger',
          },
        ],
      });
      expect(c.enabled, isTrue);
      expect(c.cashAllowed, isFalse);
      expect(c.airportWaitMinutes, 45);
      expect(c.vehicleTypes, hasLength(2));
      expect(c.rideTypes.single.vehicleTypeId, 'eco');
      expect(c.typeById('eco')!.fee, 40);
      expect(c.typeById('eco')!.lateCancelFee, 60);
    });

    test('options: locked fare, fee and unbookable reason', () {
      final list = AdvanceOption.listFrom({
        'scheduled_at': '2026-11-21T23:30:00Z',
        'options': [
          {
            'vehicle_type_id': 'eco',
            'display_name': 'Economy',
            'advance_booking_fee': 40,
            'min_lead_minutes': 60,
            'late_cancel_fee': 60,
            'fare': 185,
            'ride_fare': 145,
            'bookable': true,
            'free_cancel_until': '2026-11-21T22:30:00Z',
            'seats': 4,
          },
          {
            'vehicle_type_id': 'suv',
            'display_name': 'SUV',
            'fare': 300,
            'ride_fare': 260,
            'bookable': false,
            'reason': 'TOO_SOON',
          },
        ],
      });
      expect(list, hasLength(2));
      expect(list.first.fare, 185);
      expect(list.first.rideFare, 145);
      expect(list.first.type.fee, 40);
      expect(list.first.seats, 4);
      expect(list.first.freeCancelUntil, DateTime.utc(2026, 11, 21, 22, 30));
      expect(list.last.bookable, isFalse);
      expect(list.last.reason, 'TOO_SOON');
      expect(AdvanceOption.listFrom(null), isEmpty);
    });
  });

  testWidgets('time sheet shows the range and the vehicle lead note', (
    tester,
  ) async {
    final config = AdvanceConfig.fromJson({
      'enabled': true,
      'min_lead_minutes': 30,
      'max_days': 7,
      'slot_minutes': 5,
    });
    const suv = AdvanceVehicleType(
      vehicleTypeId: 'suv',
      displayName: 'SUV 6 ที่นั่ง',
      minLeadMinutes: 120,
    );
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                AdvanceTimeSheet(config: config, vehicle: suv, now: now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('จองได้ตั้งแต่ วันนี้ 13:35 ถึง ส. 28 พ.ย.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('advanceVehicleLeadNote')), findsOneWidget);
    expect(
      find.text(
        'SUV 6 ที่นั่ง ต้องจองก่อน 2 ชั่วโมง จะเลือกได้ตั้งแต่ วันนี้ 15:05',
      ),
      findsOneWidget,
    );
    expect(find.text('จองล่วงหน้า · วันนี้ 13:35'), findsOneWidget);
    expect(picked, isNull);
  });

  test('policy line joins the known parts', () {
    // Uses the real Thai strings through a lookup.
    final l10n = lookupAppLocalizations(const Locale('th'));
    expect(
      advancePolicyLine(
        l10n,
        freeCancelUntil: '05:30',
        lateCancelFee: '60',
        waitMinutes: 10,
      ),
      'ยกเลิกฟรีถึง 05:30 · หลังจากนั้นเสีย ฿60 ถ้ามีคนขับรับงานแล้ว · คนขับรอได้ 10 นาที',
    );
    expect(advancePolicyLine(l10n, waitMinutes: 0), '');
  });

  testWidgets('confirm time card shows the time and goes back to change it', (
    tester,
  ) async {
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvanceWhenCard(
            label: 'เวลารับ',
            month: 'พ.ย.',
            day: 24,
            weekday: 'อังคาร',
            time: '11:15 น.',
            fullDate: 'วันอังคารที่ 24 พฤศจิกายน 2569',
            changeLabel: 'เปลี่ยน',
            onChange: () => changed++,
          ),
        ),
      ),
    );
    expect(find.text('เวลารับ'), findsOneWidget);
    expect(find.text('11:15 น.'), findsOneWidget);
    expect(find.text('วันอังคารที่ 24 พฤศจิกายน 2569'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    await tester.tap(find.byKey(const Key('advanceConfirmChangeTime')));
    expect(changed, 1);
  });

  group('confirm redesign', () {
    final l10n = lookupAppLocalizations(const Locale('th'));

    test('short place keeps the whole address after a bare house number', () {
      expect(
        advanceShortPlace('ท่าอากาศยานสุวรรณภูมิ, 999 หนองปรือ'),
        'ท่าอากาศยานสุวรรณภูมิ',
      );
      expect(
        advanceShortPlace('338, ซ. สุขุมวิท 21, คลองเตย'),
        '338, ซ. สุขุมวิท 21, คลองเตย',
      );
      expect(advanceShortPlace('12/3-4, ถ. พระราม 9'), '12/3-4, ถ. พระราม 9');
      expect(advanceShortPlace('338,'), '338');
      expect(advanceShortPlace('338, '), '338');
    });

    test('trip distance and time come from the options body', () {
      final t = AdvanceOption.tripFrom({
        'distance_km': 32.4,
        'duration_min': 35,
      });
      expect(t.distanceKm, 32.4);
      expect(t.durationMin, 35);
      final none = AdvanceOption.tripFrom({'distance_km': 0});
      expect(none.distanceKm, isNull);
      expect(none.durationMin, isNull);
      expect(
        advanceTripLine(l10n, distanceKm: 32.4, durationMin: 35),
        '32 กม. · ประมาณ 35 นาที',
      );
      expect(advanceTripLine(l10n, distanceKm: 4.5), '4.5 กม.');
      expect(advanceTripLine(l10n), isNull);
    });

    test('an address splits into the place name and the rest', () {
      expect(advanceSplitPlace('Asok BTS Station, 348 ถ. สุขุมวิท'), (
        'Asok BTS Station',
        '348 ถ. สุขุมวิท',
      ));
      expect(advanceSplitPlace('338,'), ('338', ''));
      expect(advanceSplitPlace('338, '), ('338', ''));
    });

    test('policy parts are one per rule', () {
      expect(
        advancePolicyParts(
          l10n,
          freeCancelUntil: 'อ. 24 พ.ย. 10:15',
          lateCancelFee: '60',
          waitMinutes: 10,
        ),
        [
          'ยกเลิกฟรีถึง อ. 24 พ.ย. 10:15',
          'หลังจากนั้นเสีย ฿60 ถ้ามีคนขับรับงานแล้ว',
          'คนขับรอได้ 10 นาที',
        ],
      );
    });

    testWidgets('route summary and policy notice render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdvanceRouteSummary(
                  pickup: 'ท่าอากาศยานสุวรรณภูมิ, 999 หนองปรือ',
                  dropoff: 'Asok BTS Station, 348 ถ. สุขุมวิท',
                  footer: '32 กม. · ประมาณ 35 นาที',
                ),
                const AdvancePolicyNotice(
                  title: 'ก่อนจอง โปรดทราบ',
                  lines: ['ยกเลิกฟรีถึง อ. 24 พ.ย. 10:15'],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('ท่าอากาศยานสุวรรณภูมิ'), findsOneWidget);
      expect(find.text('999 หนองปรือ'), findsOneWidget);
      expect(find.byKey(const Key('advanceTripLine')), findsOneWidget);
      expect(find.text('ก่อนจอง โปรดทราบ'), findsOneWidget);
      expect(find.text('ยกเลิกฟรีถึง อ. 24 พ.ย. 10:15'), findsOneWidget);
    });
  });

  test('full date is Thai with the Buddhist year', () {
    // Tue 24 Nov 2026, 11:15 Bangkok.
    final at = DateTime.utc(2026, 11, 24, 4, 15);
    const th = AdvanceFormat('th');
    expect(th.fullDate(at), 'วันอังคารที่ 24 พฤศจิกายน 2569');
    expect(th.clockLong(at), '11:15 น.');
    expect(th.monthShort(at), 'พ.ย.');
    expect(th.weekdayName(at), 'อังคาร');
    expect(th.dayOfMonth(at), 24);
    const en = AdvanceFormat('en');
    expect(en.fullDate(at), 'Tuesday 24 November 2026');
    expect(en.clockLong(at), '11:15');
  });

  test('promo discount counts only for the fare it was checked against', () {
    const economy = AdvanceOption(
      type: AdvanceVehicleType(vehicleTypeId: 'eco', displayName: 'Economy'),
      fare: 185,
      rideFare: 145,
      bookable: true,
    );
    const none = AdvanceBookingState();
    expect(none.discountFor(economy), 0);
    const checked = AdvanceBookingState(
      promoCode: 'AGAIN',
      promoDiscount: 58,
      promoBase: 145,
    );
    expect(checked.discountFor(economy), 58);
    // Checked against another vehicle's fare: not shown until re-checked.
    const stale = AdvanceBookingState(
      promoCode: 'AGAIN',
      promoDiscount: 58,
      promoBase: 190,
    );
    expect(stale.discountFor(economy), 0);
    // Never more than the ride fare (the advance fee isn't discounted).
    const big = AdvanceBookingState(
      promoCode: 'BIG',
      promoDiscount: 500,
      promoBase: 145,
    );
    expect(big.discountFor(economy), 145);
  });
}
