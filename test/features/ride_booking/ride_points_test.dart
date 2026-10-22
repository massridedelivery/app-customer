import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/ride_booking/data/datasources/ride_booking_remote_datasource.dart';
import 'package:customer_app/features/ride_booking/data/repositories/ride_booking_repository_impl.dart';
import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/domain/repositories/ride_booking_repository.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/ride_confirm_view.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _points({
  int balance = 500,
  int max = 130,
  int used = 0,
  String? reason,
  String? errorCode,
}) => {
  'enabled': true,
  'balance': balance,
  'baht_per_point': 1,
  'min_redeem': 1,
  'max_usable_points': max,
  'used_points': used,
  'discount': used.toDouble(),
  'reason_unavailable': reason,
  'total_after_points': 130 - used,
  'error_code': ?errorCode,
};

Map<String, dynamic> _estimation({
  double gross = 180,
  double discount = 50,
  double? amountToPay,
  Map<String, dynamic>? points,
  Map<String, dynamic>? promo,
}) => {
  'vehicle_type_id': 'car',
  'vehicle_type_name': 'car_comfort',
  'display_name': 'Comfort',
  'base_fare': gross,
  'gross_fare': gross,
  'discount': discount,
  'total_fare': gross - discount,
  'surged_fare': gross,
  'amount_to_pay': amountToPay ?? (gross - discount),
  'promo': promo,
  'points': points ?? _points(),
};

/// Records every estimate / booking and answers from a script.
class _FakeRepo implements RideBookingRepository {
  final estimates = <({String? promo, bool? use, int? amount})>[];
  final bookings = <({String payment, String? promo, bool? use, int? amount})>[];

  /// Next estimate answers: an estimation map or an ApiError to throw.
  final estimateScript = <Object>[];
  Object? bookingAnswer;

  @override
  Future<FareEstimationResponse> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
    bool? usePoints,
    int? pointsToUse,
  }) async {
    estimates.add((promo: promoCode, use: usePoints, amount: pointsToUse));
    final next = estimateScript.isEmpty
        ? _estimation()
        : estimateScript.removeAt(0);
    if (next is ApiError) throw next;
    return FareEstimationResponse.fromJson({
      'distance_km': 4.2,
      'duration_min': 14,
      'estimations': [next],
    });
  }

  @override
  Future<RideBooking> createJob({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
    bool? usePoints,
    int? pointsToUse,
  }) async {
    bookings.add((
      payment: paymentMethod,
      promo: promoCode,
      use: usePoints,
      amount: pointsToUse,
    ));
    final a = bookingAnswer;
    if (a is ApiError) throw a;
    return a as RideBooking? ?? const RideBooking(id: 'job-1');
  }

  @override
  Future<double> validatePromo(String code, double subtotal) async => 0;

  @override
  Future<List<RidePromo>> getDiscoverPromos() async => const [];
}

const _a = LatLng(13.75, 100.50);
const _b = LatLng(13.74, 100.53);

late SharedPreferences _prefs;

ProviderContainer _container(_FakeRepo repo) {
  final c = ProviderContainer(
    overrides: [
      rideBookingRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(_prefs),
    ],
  );
  addTearDown(c.dispose);
  // Keep the auto-dispose controller alive for the whole test.
  c.listen(bookingControllerProvider, (_, _) {});
  return c;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('quotes', () {
    test('parse promo / points / booking', () {
      final e = VehicleEstimation.fromJson(
        _estimation(
          amountToPay: 0,
          points: _points(used: 130),
          promo: {
            'code': 'K7QM2X',
            'applied': true,
            'discount': 50,
            'kind': 'REFERRAL',
            'label': 'โค้ดเพื่อน',
          },
        ),
      );
      expect(e.payable, 0);
      expect(e.promo!.kind, 'REFERRAL');
      expect(e.points!.usedPoints, 130);
      expect(e.points!.usable, isTrue);
      final b = RideBooking.fromJson({
        'id': 'j',
        'amount_due': 0,
        'points_used': 130,
        'promo': {'code': 'RW-1', 'applied': false},
      });
      expect(b.pointsUsed, 130);
      expect(b.promo!.applied, isFalse);
    });

    test('no amount_to_pay (guest / old payload) falls back to total_fare', () {
      final json = _estimation()..remove('amount_to_pay');
      expect(VehicleEstimation.fromJson(json).payable, 130);
    });
  });

  group('controller', () {
    test('switch on asks for the maximum (use_points, no amount)', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      final n = c.read(bookingControllerProvider.notifier);
      await n.estimateFare(_a, _b, promoCode: 'K7QM2X');
      await n.setUsePoints(true, _a, _b);
      // On = all allowed: use_points only, never an amount.
      expect(repo.estimates.last, (promo: 'K7QM2X', use: true, amount: null));
      await n.setUsePoints(false, _a, _b);
      expect(repo.estimates.last.use, isNull);
    });

    test('POINTS_DISABLED hides points and prices without them', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      final n = c.read(bookingControllerProvider.notifier);
      await n.estimateFare(_a, _b);
      repo.estimateScript.add(
        const ApiError(code: 'POINTS_DISABLED', message: 'ปิด'),
      );
      await n.setUsePoints(true, _a, _b);
      final st = c.read(bookingControllerProvider).value!;
      expect(st.pointsDisabled, isTrue);
      expect(st.usePoints, isFalse);
      expect(repo.estimates.last.use, isNull);
    });

    test('a ฿0 ride books as CASH with the same points choice', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      final n = c.read(bookingControllerProvider.notifier);
      n.setPaymentMethod('PROMPTPAY');
      repo.estimateScript.addAll([
        _estimation(),
        _estimation(amountToPay: 0, points: _points(used: 130)),
      ]);
      await n.estimateFare(_a, _b, promoCode: 'K7QM2X');
      n.setVehicleType('car');
      await n.setUsePoints(true, _a, _b);
      final outcome = await n.dispatchRide(
        pickup: _a,
        dropoff: _b,
        pickupAddress: 'A',
        dropoffAddress: 'B',
      );
      expect(outcome, DispatchOutcome.booked);
      expect(repo.bookings.single, (
        payment: 'CASH',
        promo: 'K7QM2X',
        use: true,
        amount: null,
      ));
    });

    test('a refused friend code drops the code, re-prices, books nothing', () async {
      final repo = _FakeRepo()
        ..bookingAnswer = const ApiError(
          code: 'REFERRAL_OWN_CODE',
          message: 'ใช้โค้ดแนะนำของตัวเองไม่ได้',
        );
      final c = _container(repo);
      final n = c.read(bookingControllerProvider.notifier);
      await n.estimateFare(_a, _b, promoCode: 'K7QM2X');
      n.setVehicleType('car');
      final outcome = await n.dispatchRide(
        pickup: _a,
        dropoff: _b,
        pickupAddress: 'A',
        dropoffAddress: 'B',
      );
      expect(outcome, DispatchOutcome.failed);
      expect(repo.estimates.last.promo, isNull);
      final st = c.read(bookingControllerProvider).value!;
      expect(st.appliedPromoCode, isNull);
      expect(st.activeJobId, isNull);
    });

    test('a booking whose code stopped applying is flagged', () async {
      final repo = _FakeRepo()
        ..bookingAnswer = const RideBooking(
          id: 'job-9',
          promo: RidePromoQuote(code: 'RW-1', applied: false),
        );
      final c = _container(repo);
      final n = c.read(bookingControllerProvider.notifier);
      await n.estimateFare(_a, _b, promoCode: 'RW-1');
      n.setVehicleType('car');
      await n.dispatchRide(
        pickup: _a,
        dropoff: _b,
        pickupAddress: 'A',
        dropoffAddress: 'B',
      );
      final st = c.read(bookingControllerProvider).value!;
      expect(st.activeJobId, 'job-9');
      expect(st.promoDroppedOnBooking, isTrue);
    });
  });

  group('confirm step', () {
    Future<void> pump(
      WidgetTester tester,
      Map<String, dynamic> estimation, {
      bool usePoints = false,
      void Function(bool)? onToggle,
    }) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final e = VehicleEstimation.fromJson(estimation);
      final state = BookingState(
        estimations: [e],
        vehicleTypeId: e.vehicleTypeId,
        appliedPromoCode: 'K7QM2X',
        usePoints: usePoints,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
                onPointsToggle: onToggle ?? (_) {},
                onPointsLogin: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final referral = {
      'code': 'K7QM2X',
      'applied': true,
      'discount': 50,
      'kind': 'REFERRAL',
      'label': 'โค้ดเพื่อน',
    };

    testWidgets('points off: balance + maximum; switch turns it on', (
      tester,
    ) async {
      bool? toggled;
      await pump(
        tester,
        _estimation(promo: referral),
        onToggle: (v) => toggled = v,
      );
      expect(find.text('มี 500 คะแนน · ใช้ได้สูงสุด 130 คะแนน'), findsOneWidget);
      expect(find.text('โค้ดเพื่อน'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ridePointsSwitch')));
      expect(toggled, isTrue);
    });

    testWidgets('paid in full by points: summary, ฿0, no payment picker', (
      tester,
    ) async {
      await pump(
        tester,
        _estimation(
          amountToPay: 0,
          points: _points(used: 130),
          promo: referral,
        ),
        usePoints: true,
      );
      expect(find.text('ใช้ 130 คะแนน −฿130'), findsOneWidget);
      expect(find.byKey(const Key('ridePriceSummary')), findsOneWidget);
      Finder inSummary(String text) => find.descendant(
        of: find.byKey(const Key('ridePriceSummary')),
        matching: find.text(text),
      );
      expect(inSummary('฿180'), findsOneWidget);
      expect(inSummary('โค้ดเพื่อน (K7QM2X)'), findsOneWidget);
      expect(inSummary('−฿50'), findsOneWidget);
      expect(inSummary('−฿130'), findsOneWidget);
      expect(inSummary('฿0'), findsOneWidget);
      expect(find.byKey(const Key('ridePaidByPoints')), findsOneWidget);
      expect(find.byKey(const Key('ridePaidByPointsNote')), findsOneWidget);
    });

    testWidgets('unavailable reasons grey the switch out', (tester) async {
      await pump(tester, _estimation(points: _points(reason: 'NO_POINTS')));
      expect(find.text('ยังไม่มีคะแนน'), findsOneWidget);
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNull);
    });

    testWidgets('switched off by the admin: no points row', (tester) async {
      await pump(
        tester,
        _estimation(points: _points(reason: 'DISABLED')..['enabled'] = false),
      );
      expect(find.byKey(const Key('ridePointsRow')), findsNothing);
    });
  });

  group('validate', () {
    RideBookingRepositoryImpl repo(Map<String, dynamic> answer) =>
        RideBookingRepositoryImpl(_FakeSource(answer));

    test('a refused friend code keeps its code and Thai reason', () async {
      await expectLater(
        repo({
          'applied': [],
          'rejected': [
            {
              'code': 'K7QM2X',
              'reason': 'ใช้โค้ดแนะนำของตัวเองไม่ได้',
              'error_code': 'REFERRAL_OWN_CODE',
              'kind': 'REFERRAL',
            },
          ],
        }).validatePromo('k7qm2x', 180),
        throwsA(
          isA<ApiError>()
              .having((e) => e.code, 'code', 'REFERRAL_OWN_CODE')
              .having((e) => e.message, 'message', 'ใช้โค้ดแนะนำของตัวเองไม่ได้'),
        ),
      );
    });

    test('an unknown plain promo says "ไม่พบโค้ดนี้หรือใช้ไม่ได้"', () async {
      await expectLater(
        repo({
          'applied': [],
          'rejected': [
            {'code': 'NOPE', 'reason': 'something odd'},
          ],
        }).validatePromo('NOPE', 180),
        throwsA(
          isA<ApiError>().having(
            (e) => e.message,
            'message',
            'ไม่พบโค้ดนี้หรือใช้ไม่ได้',
          ),
        ),
      );
    });
  });
}

class _Fixed extends BookingController {
  _Fixed(this._state);
  final BookingState _state;

  @override
  Future<BookingState> build() async => _state;
}

class _FakeSource implements RideBookingRemoteDataSource {
  _FakeSource(this.answer);
  final Map<String, dynamic> answer;

  @override
  Future<Map<String, dynamic>> validatePromo(String code, double subtotal) async =>
      answer;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
