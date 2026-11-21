import 'package:customer_app/features/advance_booking/domain/scheduled_ride.dart';
import 'package:customer_app/features/advance_booking/presentation/scheduled_ride_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  String jobId,
  List<ScheduledRide> rides,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [scheduledRidesProvider.overrideWith((ref) async => rides)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: ScheduledRideScreen(jobId: jobId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final ride = ScheduledRide.fromJson({
    'id': 'j1',
    'status': 'PENDING',
    // 07:30 in Bangkok.
    'scheduled_at': '2026-11-22T00:30:00Z',
    'pickup_address': 'บ้าน',
    'dropoff_address': 'สนามบินสุวรรณภูมิ',
    'fare': 240,
    'advance_booking_fee': 40,
    'advance_policy': {'free_cancel_minutes': 60, 'late_cancel_fee': 60},
  });

  testWidgets('shows the booking in Bangkok time with its policy', (
    tester,
  ) async {
    await _pump(tester, 'j1', [ride]);
    expect(find.textContaining('07:30'), findsWidgets);
    expect(find.text('รวมค่าบริการจองล่วงหน้า ฿40'), findsOneWidget);
    expect(find.textContaining('ยกเลิกฟรีถึง'), findsOneWidget);
    expect(
      find.text('หลังจากนั้นเสีย ฿60 ถ้ามีคนขับรับงานแล้ว'),
      findsOneWidget,
    );
    expect(find.text('รอคนขับรับงาน'), findsOneWidget);
    expect(find.byKey(const Key('scheduledRideCancel')), findsOneWidget);
  });

  testWidgets('a booking no longer listed says so', (tester) async {
    await _pump(tester, 'gone', [ride]);
    expect(find.byKey(const Key('scheduledRideNotFound')), findsOneWidget);
  });
}
