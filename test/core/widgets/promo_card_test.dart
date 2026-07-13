import 'package:customer_app/core/widgets/promo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: child),
  ),
);

void main() {
  group('PromoCardShell', () {
    testWidgets('renders its child content', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: PromoCardShell(
              isSelected: false,
              accentColor: Colors.red,
              child: Text('CONTENT'),
            ),
          ),
        ),
      );
      expect(find.text('CONTENT'), findsOneWidget);
    });
  });

  group('PromoIconTile', () {
    testWidgets('renders the coupon icon in both states', (tester) async {
      await tester.pumpWidget(_host(const PromoIconTile()));
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);

      await tester.pumpWidget(_host(const PromoIconTile(active: false)));
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
    });
  });

  group('PromoApplyButton', () {
    testWidgets('apply state shows the use label and fires onApply', (
      tester,
    ) async {
      var applied = false;
      await tester.pumpWidget(
        _host(
          PromoApplyButton(
            isSelected: false,
            onApply: () => applied = true,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ใช้คูปอง'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsNothing);

      await tester.tap(find.text('ใช้คูปอง'));
      expect(applied, isTrue);
    });

    testWidgets('selected state shows the cancel label and fires onCancel', (
      tester,
    ) async {
      var cancelled = false;
      await tester.pumpWidget(
        _host(
          PromoApplyButton(
            isSelected: true,
            onApply: () {},
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยกเลิก'), findsOneWidget);

      await tester.tap(find.text('ยกเลิก'));
      expect(cancelled, isTrue);
    });

    testWidgets('disabled apply does not fire onApply', (tester) async {
      var applied = false;
      await tester.pumpWidget(
        _host(
          PromoApplyButton(
            isSelected: false,
            isEnabled: false,
            onApply: () => applied = true,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull); // disabled

      await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
      expect(applied, isFalse);
    });

    testWidgets('honours custom labels', (tester) async {
      await tester.pumpWidget(
        _host(
          PromoApplyButton(
            isSelected: false,
            onApply: () {},
            onCancel: () {},
            applyLabel: 'APPLY',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('APPLY'), findsOneWidget);
    });
  });
}
