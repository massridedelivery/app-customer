import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/utils/ride_payable.dart';
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/ride_confirm_view.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// An unpaid cancellation fee from an earlier ride is carried onto the next one
// (backend `prior_cancel_fee`); the server's amount_to_pay / amount_due already
// include it. Covers the field being > 0, 0 and absent.

/// A ฿180 ride with a ฿50 code; [fee] is the carried cancellation fee, which
/// the server has already added to amount_to_pay. Null leaves the field out.
Map<String, dynamic> _estimation({double? fee}) => {
  'vehicle_type_id': 'car',
  'vehicle_type_name': 'car_comfort',
  'display_name': 'Comfort',
  'base_fare': 180,
  'gross_fare': 180,
  'discount': 50,
  'total_fare': 130,
  'surged_fare': 180,
  'amount_to_pay': 130 + (fee ?? 0),
  'prior_cancel_fee': ?fee,
};

Map<String, dynamic> _job({
  double? fee,
  double? amountDue,
  String paymentStatus = '',
  String status = 'PICKED_UP',
}) => {
  'id': 'job-1',
  'status': status,
  'fare': 100,
  'discount': 20,
  'payment_method': 'CASH',
  'payment_status': paymentStatus,
  'amount_due': ?amountDue,
  'prior_cancel_fee': ?fee,
};

void main() {
  group('ridePayable', () {
    test('adds the carried fee after the coupon floor', () {
      // A ฿50 code on a ฿40 fare is ฿0 — the ฿30 fee is still owed.
      expect(ridePayable(fare: 40, discount: 50, priorCancelFee: 30), 30);
      expect(ridePayable(fare: 100, discount: 20, priorCancelFee: 30), 110);
    });

    test('after PAID the computed total keeps the fee', () {
      expect(
        rideAmountDue(
          amountDue: 0,
          paymentStatus: 'PAID',
          fare: 100,
          discount: 20,
          priorCancelFee: 30,
        ),
        110,
      );
    });
  });

  group('estimate', () {
    test('> 0: payable is amount_to_pay (fee inside), never re-added', () {
      final e = VehicleEstimation.fromJson(_estimation(fee: 30));
      expect(e.priorCancelFee, 30);
      expect(e.payable, 160);
      expect(e.ridePayable, 130);
    });

    test('0 and absent: no fee', () {
      for (final json in [_estimation(fee: 0), _estimation()]) {
        final e = VehicleEstimation.fromJson(json);
        expect(e.priorCancelFee, 0);
        expect(e.payable, 130);
      }
    });

    test('older payload without amount_to_pay adds the fee to total_fare', () {
      final json = _estimation(fee: 30)..remove('amount_to_pay');
      expect(VehicleEstimation.fromJson(json).payable, 160);
    });
  });

  group('active job', () {
    DriverProfileModel profile(Map<String, dynamic> json) =>
        DriverProfileModel.fromActiveJob(
          CustomerJobsActiveModel.fromJson(json),
        );

    test('uses amount_due (fee inside) while unpaid', () {
      final p = profile(_job(fee: 30, amountDue: 110));
      expect(p.priorCancelFee, 30);
      expect(p.payable, 110);
    });

    test('after PAID computes fare − discount + fee', () {
      expect(
        profile(_job(fee: 30, amountDue: 0, paymentStatus: 'PAID')).payable,
        110,
      );
    });

    test('0 and absent: no fee', () {
      expect(profile(_job(fee: 0, amountDue: 80)).priorCancelFee, 0);
      expect(profile(_job(amountDue: 80)).priorCancelFee, 0);
      expect(profile(_job()).payable, 80);
    });
  });

  group('history', () {
    HistoryRideDetails ride(Map<String, dynamic> json) =>
        HistoryRideDetails.fromJson(json);

    test('a completed ride shows the fee it collected', () {
      final r = ride(
        _job(fee: 30, amountDue: 0, paymentStatus: 'PAID', status: 'COMPLETED'),
      );
      expect(r.carriedCancelFee, 30);
      expect(r.payable, 110);
    });

    test('a cancelled ride never shows the fee as paid', () {
      final r = ride(_job(fee: 30, amountDue: 110, status: 'CANCELLED'));
      expect(r.carriedCancelFee, 0);
      expect(r.payable, 80);
    });

    test('0 and absent: no fee', () {
      expect(ride(_job(fee: 0, status: 'COMPLETED')).payable, 80);
      expect(ride(_job(status: 'COMPLETED')).carriedCancelFee, 0);
    });
  });

  group('confirm step', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(WidgetTester tester, Map<String, dynamic> json) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final e = VehicleEstimation.fromJson(json);
      final state = BookingState(
        estimations: [e],
        vehicleTypeId: e.vehicleTypeId,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bookingControllerProvider.overrideWith(() => _Fixed(state)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('th'),
            home: Scaffold(
              body: RideConfirmView(
                onBack: () {},
                onRequest: () {},
                onPromoTap: () {},
                onPointsLogin: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String total(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('rideTotalAmount'))).data!;

    testWidgets('> 0: its own line, a note, and amount_to_pay as the total', (
      tester,
    ) async {
      await pump(tester, _estimation(fee: 30));
      final line = find.byKey(const Key('rideSummaryPriorCancelFee'));
      expect(line, findsOneWidget);
      expect(
        find.descendant(of: line, matching: find.text('ค่ายกเลิกงานครั้งก่อน')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: line, matching: find.text('+฿30')),
        findsOneWidget,
      );
      expect(
        find.text('ยอดนี้รวมอยู่ในค่าโดยสารที่ต้องชำระแล้ว'),
        findsOneWidget,
      );
      expect(total(tester), '฿160');
      expect(find.text('เรียกรถ · ฿160'), findsOneWidget);
    });

    testWidgets('0 and absent: no line', (tester) async {
      for (final json in [_estimation(fee: 0), _estimation()]) {
        await pump(tester, json);
        expect(
          find.byKey(const Key('rideSummaryPriorCancelFee')),
          findsNothing,
        );
        expect(total(tester), '฿130');
      }
    });
  });

  test('cancel copy says the fee moves to the next ride', () {
    final th = lookupAppLocalizations(const Locale('th'));
    expect(th.liveCancelFeeConfirm('40'), contains('การเรียกรถครั้งถัดไป'));
    expect(th.liveCancelledWithFee('40'), contains('การเรียกรถครั้งถัดไป'));
  });
}

class _Fixed extends BookingController {
  _Fixed(this._state);
  final BookingState _state;

  @override
  Future<BookingState> build() async => _state;
}
