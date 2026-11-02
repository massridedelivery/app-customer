import 'package:customer_app/core/utils/plate_format.dart';
import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:customer_app/features/live_ride/presentation/screens/rating_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DriverProfileModel _driver(String province) => DriverProfileModel.fromActiveJob(
  CustomerJobsActiveModel.fromJson({
    'id': 'job1',
    'status': 'COMPLETED',
    'driver_info': {
      'full_name': 'สมชาย ขับดี',
      'vehicle_plate': '1กข 1234',
      'vehicle_color': 'ขาว',
      'vehicle_model': 'Toyota Vios',
      'vehicle_province': province,
    },
  }),
);

Future<void> _pumpRating(WidgetTester tester, String province) async {
  // A narrow phone, so a long province has to wrap.
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: RatingScreen(jobId: 'job1', driverProfile: _driver(province)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('formatPlate', () {
    test('plate and province', () {
      expect(
        formatPlate('1กข 1234', 'กรุงเทพมหานคร'),
        '1กข 1234 กรุงเทพมหานคร',
      );
    });

    test('no province: the plate alone, no placeholder', () {
      expect(formatPlate('1กข 1234', ''), '1กข 1234');
      expect(formatPlate('1กข 1234', null), '1กข 1234');
      expect(formatPlate('1กข 1234', '   '), '1กข 1234');
    });

    test('no plate: nothing, even with a province', () {
      expect(formatPlate('', 'กรุงเทพมหานคร'), '');
      expect(formatPlate(null, 'กรุงเทพมหานคร'), '');
      expect(formatPlate(null, null), '');
    });

    test('trims both parts', () {
      expect(formatPlate(' 1กข 1234 ', ' เชียงใหม่ '), '1กข 1234 เชียงใหม่');
    });
  });

  group('RatingScreen vehicle line', () {
    testWidgets('shows the province after the plate', (tester) async {
      await _pumpRating(tester, 'กรุงเทพมหานคร');
      expect(
        find.textContaining('1กข 1234 กรุงเทพมหานคร  •  ขาว Toyota Vios'),
        findsOneWidget,
      );
    });

    testWidgets('a driver without a province looks as before', (tester) async {
      await _pumpRating(tester, '');
      expect(
        find.textContaining('1กข 1234  •  ขาว Toyota Vios'),
        findsOneWidget,
      );
    });

    testWidgets('a long province wraps instead of overflowing', (tester) async {
      await _pumpRating(tester, 'พระนครศรีอยุธยา');
      // A RenderFlex overflow would be reported as an exception here.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('1กข 1234 พระนครศรีอยุธยา'), findsOneWidget);
    });
  });
}
