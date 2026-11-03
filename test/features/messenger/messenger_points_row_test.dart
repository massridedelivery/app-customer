import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_booking_controller.dart';
import 'package:customer_app/features/messenger/presentation/screens/messenger_booking_screen.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeController extends HomeController {
  @override
  HomeState build() => const HomeState();
}

class _FakeBooking extends MessengerBookingController {
  _FakeBooking(this.initial);
  final MessengerBookingState initial;

  @override
  MessengerBookingState build() => initial;

  @override
  Future<void> estimate() async {}
}

MessengerEstimate _estimate({required bool used}) =>
    MessengerEstimate.fromJson({
      'distance_km': 2,
      'total_fare': 49,
      'service_levels': [
        {
          'delivery_type': 'INSTANT',
          'base_fare': 49,
          'total_fare': 49,
          'amount_to_pay': used ? 19 : 49,
          'points': {
            'enabled': true,
            'balance': 30,
            'min_redeem': 10,
            'max_usable_points': 30,
            'used_points': used ? 30 : 0,
            'discount': used ? 30 : 0,
          },
        },
      ],
    });

Future<ProviderContainer> _pump(
  WidgetTester tester,
  MessengerBookingState state,
) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  final c = ProviderContainer(
    overrides: [
      homeControllerProvider.overrideWith(_FakeHomeController.new),
      messengerBookingControllerProvider.overrideWith(
        () => _FakeBooking(state),
      ),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('th'),
        home: MessengerBookingScreen(),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
}

void main() {
  testWidgets('the points switch turns points on for the booking', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      MessengerBookingState(estimate: _estimate(used: false)),
    );
    await _show(tester, find.byKey(const Key('ridePointsSwitch')));
    await tester.tap(find.byKey(const Key('ridePointsSwitch')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.read(messengerBookingControllerProvider).usePoints, isTrue);
  });

  testWidgets('points in use: the summary shows them and the lower total', (
    tester,
  ) async {
    await _pump(
      tester,
      MessengerBookingState(usePoints: true, estimate: _estimate(used: true)),
    );
    await _show(tester, find.byKey(const Key('msgrPointsLine')));
    expect(find.text('ใช้ 30 คะแนน'), findsOneWidget);
    expect(find.text('-฿30'), findsWidgets);
    expect(find.textContaining('฿19'), findsWidgets);
  });
}
