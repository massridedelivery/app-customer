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
  group('LoadingView', () {
    testWidgets('shows a progress indicator', (tester) async {
      await tester.pumpWidget(_host(const LoadingView()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ErrorRetryView', () {
    testWidgets('shows message, detail, icon and a working retry button', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        _host(
          ErrorRetryView(
            message: 'boom',
            detail: 'stack detail',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('boom'), findsOneWidget);
      expect(find.text('stack detail'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);

      await tester.tap(find.text('ลองใหม่'));
      expect(retried, isTrue);
    });

    testWidgets('omits detail and retry button when not provided', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ErrorRetryView(message: 'only msg')));
      expect(find.text('only msg'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsNothing);
    });

    testWidgets('falls back to the default message', (tester) async {
      await tester.pumpWidget(_host(const ErrorRetryView()));
      expect(find.text('เกิดข้อผิดพลาดในการโหลดข้อมูล'), findsOneWidget);
    });

    testWidgets('honours a custom retry label', (tester) async {
      await tester.pumpWidget(
        _host(ErrorRetryView(retryLabel: 'RETRY', onRetry: () {})),
      );
      expect(find.text('RETRY'), findsOneWidget);
    });
  });
}
