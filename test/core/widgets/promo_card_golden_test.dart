@Tags(['golden'])
library;

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
  Widget card(bool selected) => SizedBox(
    width: 360,
    child: PromoCardShell(
      isSelected: selected,
      accentColor: Colors.red,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('SAVE10'),
      ),
    ),
  );

  testWidgets('PromoCardShell - unselected', (tester) async {
    await tester.pumpWidget(_host(card(false)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PromoCardShell),
      matchesGoldenFile('goldens/promo_card_shell__unselected.png'),
    );
  });

  testWidgets('PromoCardShell - selected', (tester) async {
    await tester.pumpWidget(_host(card(true)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PromoCardShell),
      matchesGoldenFile('goldens/promo_card_shell__selected.png'),
    );
  });

  testWidgets('PromoApplyButton - apply', (tester) async {
    await tester.pumpWidget(
      _host(PromoApplyButton(isSelected: false, onApply: () {}, onCancel: () {})),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PromoApplyButton),
      matchesGoldenFile('goldens/promo_apply_button__apply.png'),
    );
  });

  testWidgets('PromoApplyButton - disabled', (tester) async {
    await tester.pumpWidget(
      _host(
        PromoApplyButton(
          isSelected: false,
          isEnabled: false,
          onApply: () {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PromoApplyButton),
      matchesGoldenFile('goldens/promo_apply_button__disabled.png'),
    );
  });

  testWidgets('PromoApplyButton - cancel', (tester) async {
    await tester.pumpWidget(
      _host(PromoApplyButton(isSelected: true, onApply: () {}, onCancel: () {})),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PromoApplyButton),
      matchesGoldenFile('goldens/promo_apply_button__cancel.png'),
    );
  });
}
