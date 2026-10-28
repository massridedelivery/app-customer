import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:customer_app/features/call/presentation/call_screen.dart';
import 'package:customer_app/features/call/presentation/order_call_button.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:customer_app/features/chat/presentation/widgets/chat_system_note.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A controller that only records what the screen asks of it.
class _Controller extends CallController {
  _Controller(this.initial);

  final CallSession? initial;
  final asked = <String>[];

  @override
  CallSession? build() => initial;

  @override
  Future<void> accept({bool fromSystem = false}) async => asked.add('accept');

  @override
  Future<void> decline() async => asked.add('decline');

  @override
  Future<void> hangUp({String reason = 'hangup', bool failed = false}) async =>
      asked.add('hangUp');

  @override
  Future<void> toggleMute() async => asked.add('mute');
}

const _call = CallView(
  callId: 'call-1',
  kind: CallKind.food,
  jobId: 'order-1',
  direction: 'incoming',
  peer: CallPeer(fullName: 'สมชาย', role: 'driver'),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({'call_full_screen_asked': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

Widget _button(String? status) => OrderCallButton(
  kind: CallKind.food,
  jobId: 'order-1',
  status: status,
  builder: (context, onCall) => onCall == null
      ? const Text('no call')
      : TextButton(onPressed: onCall, child: const Text('call')),
);

void main() {
  group('OrderCallButton', () {
    testWidgets('shows when calling is on and the order runs', (tester) async {
      await _pump(
        tester,
        _button('DRIVER_PICKED_UP'),
        overrides: [
          callSettingsProvider.overrideWith(
            (ref) async => const CallSettings(enabled: true),
          ),
        ],
      );
      expect(find.text('call'), findsOneWidget);
    });

    testWidgets('nothing while calling is off', (tester) async {
      await _pump(
        tester,
        _button('DRIVER_PICKED_UP'),
        overrides: [
          callSettingsProvider.overrideWith(
            (ref) async => const CallSettings(),
          ),
        ],
      );
      expect(find.text('no call'), findsOneWidget);
    });

    testWidgets('nothing before a rider is assigned', (tester) async {
      await _pump(
        tester,
        _button('PREPARING'),
        overrides: [
          callSettingsProvider.overrideWith(
            (ref) async => const CallSettings(enabled: true),
          ),
        ],
      );
      expect(find.text('no call'), findsOneWidget);
    });

    testWidgets('gone once the backend refused the order', (tester) async {
      final container = ProviderContainer(
        overrides: [
          callSettingsProvider.overrideWith(
            (ref) async => const CallSettings(enabled: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(callRefusedOrdersProvider.notifier).add('order-1');
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: _button('DRIVER_PICKED_UP')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('no call'), findsOneWidget);
    });
  });

  group('CallScreen', () {
    testWidgets('incoming: name, accept and decline', (tester) async {
      final controller = _Controller(
        const CallSession(call: _call, phase: CallPhase.incoming),
      );
      await _pump(
        tester,
        const CallScreen(),
        overrides: [callControllerProvider.overrideWith(() => controller)],
      );
      expect(find.text('สมชาย'), findsOneWidget);
      expect(find.text('สายเรียกเข้า'), findsOneWidget);
      await tester.tap(find.byKey(const Key('callAccept')));
      await tester.tap(find.byKey(const Key('callDecline')));
      expect(controller.asked, ['accept', 'decline']);
      expect(find.byKey(const Key('callHangUp')), findsNothing);
    });

    testWidgets('outgoing: กำลังโทรหา… and hang up', (tester) async {
      final controller = _Controller(
        const CallSession(call: _call, phase: CallPhase.outgoing),
      );
      await _pump(
        tester,
        const CallScreen(),
        overrides: [callControllerProvider.overrideWith(() => controller)],
      );
      expect(find.text('กำลังโทรหา…'), findsOneWidget);
      await tester.tap(find.byKey(const Key('callMute')));
      await tester.tap(find.byKey(const Key('callHangUp')));
      expect(controller.asked, ['mute', 'hangUp']);
    });

    testWidgets('active: the timer counts from the connection', (tester) async {
      final controller = _Controller(
        CallSession(
          call: _call,
          phase: CallPhase.active,
          connectedAt: DateTime.now().subtract(const Duration(seconds: 84)),
        ),
      );
      await _pump(
        tester,
        const CallScreen(),
        overrides: [callControllerProvider.overrideWith(() => controller)],
      );
      expect(find.text('1:24'), findsOneWidget);
    });

    test('duration and end texts', () {
      expect(formatCallDuration(const Duration(seconds: 5)), '0:05');
      expect(
        formatCallDuration(const Duration(minutes: 61, seconds: 2)),
        '1:01:02',
      );
    });
  });

  testWidgets('a system chat line is a centred note', (tester) async {
    final message = ChatMessage.fromJson({
      'id': 'm1',
      'sender_id': '',
      'sender_type': 'system',
      'content': '📞 โทร 1:24 นาที',
      'msg_type': 'system',
      'created_at': '2026-10-28T10:00:00Z',
    });
    expect(message.isSystem, isTrue);
    await _pump(tester, ChatSystemNote(text: message.text));
    expect(find.text('📞 โทร 1:24 นาที'), findsOneWidget);
  });
}
