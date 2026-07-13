@Tags(['golden'])
library;

import 'package:customer_app/core/widgets/async_state_view.dart';
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
  testWidgets('ErrorRetryView - full', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          height: 320,
          child: ErrorRetryView(
            message: 'ไม่สามารถโหลดข้อมูลได้',
            detail: 'Exception: timeout',
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ErrorRetryView),
      matchesGoldenFile('goldens/error_retry_view__full.png'),
    );
  });

  testWidgets('ErrorRetryView - message only', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 360,
          height: 320,
          child: ErrorRetryView(message: 'only msg'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ErrorRetryView),
      matchesGoldenFile('goldens/error_retry_view__message_only.png'),
    );
  });
}
