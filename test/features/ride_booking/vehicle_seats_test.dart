import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_item.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Object? seats}) => {
  'vehicle_type_id': 'van',
  'vehicle_type_name': 'van',
  'display_name': 'Van',
  'base_fare': 300,
  'discount': 0,
  'total_fare': 300,
  'surged_fare': 300,
  'seats': ?seats,
};

Future<void> _pump(WidgetTester tester, VehicleEstimation e) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Scaffold(
          body: VehicleSelectionItem(
            estimation: e,
            isSelected: false,
            onTap: () {},
            iconPath: 'assets/images/icons/3d/ic3d_ride.png',
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows a "N ที่นั่ง" chip when the estimate has seats', (
    tester,
  ) async {
    await _pump(tester, VehicleEstimation.fromJson(_json(seats: 10)));
    expect(find.byKey(const Key('vehicleSeats')), findsOneWidget);
    expect(find.text('10 ที่นั่ง'), findsOneWidget);
    // No "ค่าโดยสารเริ่มต้น" note on the vehicle list.
    expect(find.text('ค่าโดยสารเริ่มต้น'), findsNothing);
  });

  testWidgets('no seats, no badge', (tester) async {
    await _pump(tester, VehicleEstimation.fromJson(_json()));
    expect(find.byKey(const Key('vehicleSeats')), findsNothing);
    expect(find.text('ค่าโดยสารเริ่มต้น'), findsNothing);
  });
}
