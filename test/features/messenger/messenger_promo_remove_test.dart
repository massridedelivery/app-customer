import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
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

/// Skips the real build() (vehicle types, estimate) and starts with [code].
class _FakeBooking extends MessengerBookingController {
  _FakeBooking(this.code);
  final String code;

  @override
  MessengerBookingState build() => MessengerBookingState(promoCode: code);

  @override
  Future<void> estimate() async {}
}

Future<ProviderContainer> _pump(WidgetTester tester, String code) async {
  // A phone-sized screen: the hero header is laid out for one.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The test font draws Thai far wider than real fonts, so the fixed-height
  // hero overflows here; that layout is not what this test is about.
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  final container = ProviderContainer(
    overrides: [
      homeControllerProvider.overrideWith(_FakeHomeController.new),
      messengerBookingControllerProvider.overrideWith(() => _FakeBooking(code)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('th'),
        home: MessengerBookingScreen(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Scrolls [finder] to the middle of the form, clear of the bottom bar.
Future<void> _centre(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
}

void main() {
  testWidgets('an applied code can be taken off, as on ride', (tester) async {
    final c = await _pump(tester, 'NEW50');
    await _centre(tester, find.byKey(const Key('msgrPromoRemove')));
    expect(find.text('NEW50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('msgrPromoRemove')));
    await tester.pump();

    expect(c.read(messengerBookingControllerProvider).promoCode, '');
    expect(find.byKey(const Key('msgrPromoRemove')), findsNothing);
    expect(find.text('NEW50'), findsNothing);
    expect(find.text('ยกเลิกคูปองเรียบร้อยแล้ว'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('no code: no remove button', (tester) async {
    await _pump(tester, '');
    expect(find.byKey(const Key('msgrPromoRemove')), findsNothing);
  });

  testWidgets('a code set without this screen (welcome / voucher) shows', (
    tester,
  ) async {
    await _pump(tester, 'WELCOME20');
    await _centre(tester, find.text('WELCOME20'));
    expect(find.text('WELCOME20'), findsOneWidget);
  });

  testWidgets('back from the coupon screen: no field takes the focus', (
    tester,
  ) async {
    await _pump(tester, '');
    final phone = find.byWidgetPredicate(
      (w) => w is TextField && w.keyboardType == TextInputType.phone,
    );
    await _centre(tester, phone.first);
    await tester.tap(phone.first);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.context?.widget, isNotNull);

    await _centre(tester, find.byKey(const Key('msgrPromoRow')));
    await tester.tap(find.byKey(const Key('msgrPromoRow')));
    await tester.pumpAndSettle();
    // Leave the coupon screen without picking (its own back button).
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    final focused = FocusManager.instance.primaryFocus?.context;
    expect(
      focused?.findAncestorWidgetOfExactType<EditableText>(),
      isNull,
      reason: 'the keyboard must not come back over the summary',
    );
  });
}
