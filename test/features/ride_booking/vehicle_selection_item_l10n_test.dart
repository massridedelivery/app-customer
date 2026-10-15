import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_item.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _est = VehicleEstimation(
  vehicleTypeId: 'comfort',
  vehicleTypeName: 'car_comfort',
  displayName: 'Comfort Car',
  baseFare: 120,
  discount: 20,
  totalFare: 100,
  surgedFare: 120,
  driversNearby: 3,
);

Future<void> _pump(WidgetTester tester, String languageCode) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(languageCode),
      home: Scaffold(
        body: VehicleSelectionItem(
          estimation: _est,
          isSelected: false,
          onTap: () {},
          iconPath: 'assets/images/icons/3d/ic3d_ride.png',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('English mode renders the vehicle row in English', (
    tester,
  ) async {
    await _pump(tester, 'en');

    expect(find.text('Comfort'), findsOneWidget);
    expect(find.text('3 drivers nearby'), findsOneWidget);
    expect(find.text('฿20 off'), findsOneWidget);
    expect(find.textContaining('รถ'), findsNothing);
  });

  testWidgets('Thai mode keeps the Thai vehicle row', (tester) async {
    await _pump(tester, 'th');

    expect(find.text('รถ Comfort'), findsOneWidget);
    expect(find.text('มีคนขับใกล้ฉัน 3 คน'), findsOneWidget);
    expect(find.text('ลด ฿20'), findsOneWidget);
  });
}
