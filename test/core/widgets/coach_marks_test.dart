import 'package:customer_app/core/widgets/coach_marks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _a = GlobalKey();
final _b = GlobalKey();
final _missing = GlobalKey(); // never attached to a widget

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ctx = context;
          return Scaffold(
            body: Column(
              children: [
                SizedBox(key: _a, width: 200, height: 50),
                const SizedBox(height: 300),
                SizedBox(key: _b, width: 200, height: 50),
              ],
            ),
          );
        },
      ),
    ),
  );
  return ctx;
}

void _start(BuildContext ctx, List<GlobalKey> targets, VoidCallback onFinish) {
  showCoachMarks(
    ctx,
    steps: [
      for (var i = 0; i < targets.length; i++)
        CoachMarkStep(target: targets[i], title: 'T$i', body: 'B$i'),
    ],
    skipLabel: 'ข้าม',
    nextLabel: 'ถัดไป',
    doneLabel: 'เข้าใจแล้ว',
    onFinish: onFinish,
  );
}

void main() {
  testWidgets('walks the steps and finishes once on the last button', (
    tester,
  ) async {
    final ctx = await _pumpHost(tester);
    var finished = 0;
    _start(ctx, [_a, _b], () => finished++);
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('T0'), findsOneWidget);
    expect(find.text('ข้าม'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coachNext')));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('เข้าใจแล้ว'), findsOneWidget);
    expect(find.text('ข้าม'), findsNothing); // no skip on the last step

    await tester.tap(find.byKey(const Key('coachNext')));
    await tester.pump();
    expect(find.text('T1'), findsNothing);
    expect(finished, 1);
  });

  testWidgets('skip closes the tour and reports it finished', (tester) async {
    final ctx = await _pumpHost(tester);
    var finished = 0;
    _start(ctx, [_a, _b], () => finished++);
    await tester.pump();
    await tester.tap(find.byKey(const Key('coachSkip')));
    await tester.pump();
    expect(find.text('T0'), findsNothing);
    expect(finished, 1);
  });

  testWidgets('a step whose target is not on screen is skipped', (
    tester,
  ) async {
    final ctx = await _pumpHost(tester);
    _start(ctx, [_missing, _b], () {});
    await tester.pump();
    await tester.pump();
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
