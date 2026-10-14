import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_sheet.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed BookingState and skips the real build().
class _FakeBookingController extends BookingController {
  _FakeBookingController(this._initial);
  final BookingState _initial;

  @override
  Future<BookingState> build() async => _initial;
}

VehicleEstimation _est({required double discount}) => VehicleEstimation(
  vehicleTypeId: 'comfort',
  vehicleTypeName: 'car_comfort',
  displayName: 'Comfort',
  baseFare: 100,
  discount: discount,
  totalFare: 100 - discount,
  surgedFare: 100,
);

Future<void> _pump(WidgetTester tester, BookingState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookingControllerProvider.overrideWith(
          () => _FakeBookingController(state),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: VehicleSelectionSheet(
            scrollController: ScrollController(),
            estimations: state.estimations,
            onRequest: () {},
            onPromoTap: () {},
            onVehicleSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the discount the estimate actually applied', (
    tester,
  ) async {
    final est = _est(discount: 50);
    await _pump(
      tester,
      BookingState(
        estimations: [est],
        vehicleTypeId: est.vehicleTypeId,
        appliedPromoCode: 'RIDE50',
        // The validate call's figure must not drive the chip.
        promoDiscount: 80,
      ),
    );

    expect(find.text('ส่วนลดคูปอง RIDE50'), findsOneWidget);
    expect(find.text('-฿50'), findsOneWidget);
    expect(find.text('-฿80'), findsNothing);
  });

  testWidgets('says so when the estimate did not take the code off', (
    tester,
  ) async {
    final est = _est(discount: 0);
    await _pump(
      tester,
      BookingState(
        estimations: [est],
        vehicleTypeId: est.vehicleTypeId,
        appliedPromoCode: 'RIDE50',
        promoDiscount: 50,
      ),
    );

    expect(find.text('โค้ด RIDE50 ยังไม่ถูกหักจากค่าโดยสาร'), findsOneWidget);
    expect(find.text('-฿50'), findsNothing);
  });

  testWidgets('no coupon row without an applied code', (tester) async {
    await _pump(tester, BookingState(estimations: [_est(discount: 0)]));

    expect(find.textContaining('RIDE50'), findsNothing);
    expect(find.textContaining('ส่วนลดคูปอง'), findsNothing);
  });
}
