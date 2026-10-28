import 'dart:async';

import 'package:customer_app/features/call/data/call_media.dart';
import 'package:customer_app/features/call/data/call_repository.dart';
import 'package:customer_app/features/call/data/call_signaling.dart';
import 'package:customer_app/features/call/data/call_system_ui.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ice = [
  {
    'urls': ['stun:stun.cloudflare.com:3478'],
  },
];

Map<String, dynamic> _view({
  String callId = 'call-1',
  String status = 'ringing',
  String direction = 'outgoing',
  String? endReason,
  bool ice = true,
}) => {
  'call_id': callId,
  'kind': 'food',
  'job_id': 'order-1',
  'status': status,
  'direction': direction,
  'end_reason': ?endReason,
  'peer': {
    'user_id': 'd1',
    'full_name': 'สมชาย',
    'avatar_url': 'https://x/a.jpg',
    'role': 'driver',
  },
  if (ice) 'ice_servers': _ice,
  'ring_timeout_sec': 30,
};

class _Repo implements CallRepository {
  final calls = <String>[];
  CallException? startError;
  CallException? acceptError;
  Completer<void>? acceptGate;
  Map<String, dynamic> Function() getView = () =>
      _view(direction: 'incoming', ice: false);

  @override
  Future<CallView> start(CallKind kind, String jobId) async {
    calls.add('start ${kind.name} $jobId');
    if (startError != null) throw startError!;
    return CallView.fromJson(_view());
  }

  @override
  Future<CallView> get(String callId) async {
    calls.add('get $callId');
    return CallView.fromJson(getView());
  }

  @override
  Future<CallView> accept(String callId) async {
    calls.add('accept $callId');
    await acceptGate?.future;
    if (acceptError != null) throw acceptError!;
    return CallView.fromJson(_view(status: 'accepted', direction: 'incoming'));
  }

  @override
  Future<CallView> decline(String callId) async {
    calls.add('decline $callId');
    return CallView.fromJson(_view(status: 'ended'));
  }

  @override
  Future<CallView> end(String callId, {bool failed = false}) async {
    calls.add('end $callId${failed ? ' failed' : ''}');
    return CallView.fromJson(_view(status: 'ended'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Media implements CallMedia {
  final log = <String>[];
  bool micRefused = false;
  final candidateCtl = StreamController<Map<String, dynamic>>.broadcast();
  final stateCtl = StreamController<CallMediaState>.broadcast();
  List<Map<String, dynamic>>? iceServers;
  bool closed = false;

  @override
  Stream<Map<String, dynamic>> get candidates => candidateCtl.stream;

  @override
  Stream<CallMediaState> get states => stateCtl.stream;

  @override
  Future<void> openMicrophone() async {
    log.add('mic');
    if (micRefused) throw Exception('denied');
  }

  @override
  Future<void> connect(List<Map<String, dynamic>> iceServers) async {
    this.iceServers = iceServers;
    log.add('connect');
  }

  @override
  Future<Map<String, dynamic>> createOffer({bool iceRestart = false}) async {
    log.add(iceRestart ? 'offer restart' : 'offer');
    return {'type': 'offer', 'sdp': 'o'};
  }

  @override
  Future<Map<String, dynamic>> createAnswer() async {
    log.add('answer');
    return {'type': 'answer', 'sdp': 'a'};
  }

  @override
  Future<void> setRemoteDescription(Map<String, dynamic> d) async =>
      log.add('remote ${d['type']}');

  @override
  Future<void> addCandidate(Map<String, dynamic> c) async =>
      log.add('candidate ${c['candidate']}');

  @override
  Future<void> setMuted(bool muted) async => log.add('muted $muted');

  @override
  Future<void> setSpeaker(bool on) async => log.add('speaker $on');

  @override
  Future<void> close() async {
    closed = true;
    log.add('close');
  }
}

class _Signaling implements CallSignaling {
  final frameCtl = StreamController<Map<String, dynamic>>.broadcast();
  final sent = <Map<String, dynamic>>[];

  @override
  Stream<Map<String, dynamic>> get frames => frameCtl.stream;

  @override
  bool send(Map<String, dynamic> frame) {
    sent.add(frame);
    return true;
  }

  @override
  Future<bool> connect({Duration timeout = const Duration(seconds: 6)}) async =>
      true;

  @override
  void release() {}

  List<String> get signals => [for (final f in sent) f['kind'] as String];
}

class _SystemUi implements CallSystemUi {
  final eventCtl = StreamController<SystemCallEvent>.broadcast();
  final log = <String>[];
  List<({String callId, bool accepted, Map<String, dynamic> extra})> active =
      [];

  @override
  Stream<SystemCallEvent> get events => eventCtl.stream;

  @override
  Future<void> showIncoming(
    CallView call, {
    Map<String, dynamic>? extra,
  }) async => log.add('incoming ${call.callId}');

  @override
  Future<void> startOutgoing(CallView call) async =>
      log.add('outgoing ${call.callId}');

  @override
  Future<void> setConnected(String callId) async =>
      log.add('connected $callId');

  @override
  Future<void> end(String callId) async => log.add('end $callId');

  @override
  Future<List<({String callId, bool accepted, Map<String, dynamic> extra})>>
  activeCalls() async => active;

  @override
  Future<String?> voipToken() async => null;
}

class _Harness {
  _Harness({
    List<({String callId, bool accepted, Map<String, dynamic> extra})>
        systemCalls =
        const [],
  }) {
    systemUi.active = systemCalls;
    container = ProviderContainer(
      overrides: [
        callRepositoryProvider.overrideWithValue(repo),
        callSignalingProvider.overrideWithValue(signaling),
        callSystemUiProvider.overrideWithValue(systemUi),
        callMediaFactoryProvider.overrideWithValue(() {
          final m = _Media()..micRefused = micRefused;
          medias.add(m);
          return m;
        }),
        callNetworkChangesProvider.overrideWithValue(network.stream),
        callScreenOpenerProvider.overrideWithValue(() => screenOpened++),
      ],
    );
    controller.start();
  }

  late final ProviderContainer container;
  final repo = _Repo();
  final signaling = _Signaling();
  final systemUi = _SystemUi();
  final network = StreamController<void>.broadcast();
  final medias = <_Media>[];
  bool micRefused = false;
  int screenOpened = 0;

  CallController get controller =>
      container.read(callControllerProvider.notifier);
  CallSession? get session => container.read(callControllerProvider);
  _Media get media => medias.last;

  void frame(Map<String, dynamic> f) => signaling.frameCtl.add(f);

  void signal(String kind, Map<String, dynamic> payload) => frame({
    'type': 'call_signal',
    'call_id': 'call-1',
    'kind': kind,
    'payload': payload,
  });

  void dispose() => container.dispose();
}

/// Lets queued microtasks and stream events run.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

DioException _dio(int status, [String? code]) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: {'error': 'x', 'code': ?code},
  ),
);

void main() {
  group('isOrderCallable', () {
    final now = DateTime(2026, 10, 28, 12);

    test('rides: accepted, at pick-up, picked up; completed for 24h', () {
      for (final s in ['ACCEPTED', 'ARRIVED_AT_PICK_UP', 'PICKED_UP']) {
        expect(isOrderCallable(CallKind.ride, s), isTrue, reason: s);
      }
      for (final s in ['PENDING', 'CANCELLED', null]) {
        expect(isOrderCallable(CallKind.ride, s), isFalse, reason: '$s');
      }
      expect(
        isOrderCallable(
          CallKind.ride,
          'COMPLETED',
          doneAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        isTrue,
      );
      expect(
        isOrderCallable(
          CallKind.ride,
          'COMPLETED',
          doneAt: now.subtract(const Duration(hours: 30)),
          now: now,
        ),
        isFalse,
      );
    });

    test('food: rider assigned / picked up; delivered; never before', () {
      expect(isOrderCallable(CallKind.food, 'DRIVER_ASSIGNED'), isTrue);
      expect(isOrderCallable(CallKind.food, 'DRIVER_PICKED_UP'), isTrue);
      expect(isOrderCallable(CallKind.food, 'DELIVERED'), isTrue);
      expect(isOrderCallable(CallKind.food, 'PREPARING'), isFalse);
      expect(isOrderCallable(CallKind.food, 'ACCEPTED'), isFalse);
    });

    test('messenger: ARRIVED_AT_PICKUP (not the ride spelling)', () {
      expect(isOrderCallable(CallKind.messenger, 'ARRIVED_AT_PICKUP'), isTrue);
      expect(
        isOrderCallable(CallKind.messenger, 'ARRIVED_AT_PICK_UP'),
        isFalse,
      );
      expect(isOrderCallable(CallKind.messenger, 'delivered'), isTrue);
    });
  });

  group('models', () {
    test('a push carries strings only', () {
      final call = CallView.fromPush({
        'type': 'call_incoming',
        'call_id': 'c9',
        'kind': 'messenger',
        'job_id': 'm1',
        'caller_name': 'สมศรี',
        'caller_role': 'driver',
        'ring_timeout_sec': '30',
      })!;
      expect(call.kind, CallKind.messenger);
      expect(call.ringTimeoutSec, 30);
      expect(call.isIncoming, isTrue);
      expect(call.peer.avatarUrl, isNull);
    });

    test('a call view keeps ice_servers as they are', () {
      final call = CallView.fromJson(_view());
      expect(call.iceServers, _ice);
      expect(call.peer.fullName, 'สมชาย');
    });

    test('error codes map to what the customer is told', () {
      expect(
        CallException.fromDio(_dio(409, 'CALL_BUSY')).error,
        CallError.busy,
      );
      expect(
        CallException.fromDio(_dio(409, 'CALL_NOT_ALLOWED')).error,
        CallError.notAllowed,
      );
      expect(
        CallException.fromDio(_dio(403, 'CALL_BLOCKED')).error,
        CallError.blocked,
      );
      expect(
        CallException.fromDio(_dio(503, 'CALL_DISABLED')).error,
        CallError.disabled,
      );
      expect(
        CallException.fromDio(_dio(409, 'CALL_ENDED')).error,
        CallError.ended,
      );
      expect(CallException.fromDio(_dio(404)).error, CallError.notFound);
      expect(CallException.fromDio(_dio(500)).error, CallError.failed);
    });
  });

  group('calling the driver', () {
    late _Harness h;
    setUp(() => h = _Harness());
    tearDown(() => h.dispose());

    test('rings, offers only after call_accepted, trickles ICE', () async {
      expect(await h.controller.startCall(CallKind.food, 'order-1'), isNull);
      expect(h.repo.calls, ['start food order-1']);
      expect(h.session!.phase, CallPhase.outgoing);
      expect(h.screenOpened, 1);
      expect(h.systemUi.log, ['outgoing call-1']);
      expect(h.media.log, ['mic']);
      expect(h.signaling.sent, isEmpty, reason: 'no offer while ringing');

      h.frame({'type': 'call_accepted', 'call': _view(status: 'accepted')});
      await _settle();
      expect(h.session!.phase, CallPhase.connecting);
      expect(h.media.iceServers, _ice);
      expect(h.signaling.sent.single, {
        'type': 'call_signal',
        'call_id': 'call-1',
        'kind': 'offer',
        'payload': {'type': 'offer', 'sdp': 'o'},
      });

      // A candidate before the answer waits for it.
      h.signal('ice', {'candidate': 'c1', 'sdpMid': '0', 'sdpMLineIndex': 0});
      await _settle();
      expect(h.media.log, isNot(contains('candidate c1')));
      h.signal('answer', {'type': 'answer', 'sdp': 'a'});
      await _settle();
      expect(h.media.log.sublist(h.media.log.indexOf('remote answer')), [
        'remote answer',
        'candidate c1',
      ]);

      h.media.candidateCtl.add({
        'candidate': 'mine',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });
      await _settle();
      expect(h.signaling.sent.last['kind'], 'ice');
      expect(h.signaling.sent.last['payload']['candidate'], 'mine');

      h.media.stateCtl.add(CallMediaState.connected);
      await _settle();
      expect(h.session!.phase, CallPhase.active);
      expect(h.session!.connectedAt, isNotNull);
      expect(h.systemUi.log, contains('connected call-1'));
    });

    test('frames of another call are ignored', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      h.frame({
        'type': 'call_accepted',
        'call': _view(callId: 'other', status: 'accepted'),
      });
      await _settle();
      expect(h.session!.phase, CallPhase.outgoing);
    });

    test('busy: no call, the reason comes back', () async {
      h.repo.startError = CallException.fromDio(_dio(409, 'CALL_BUSY'));
      expect(
        await h.controller.startCall(CallKind.food, 'order-1'),
        CallError.busy,
      );
      expect(h.session, isNull);
      expect(h.screenOpened, 0);
      expect(h.media.closed, isTrue);
    });

    test('not allowed: the order loses its button', () async {
      h.repo.startError = CallException.fromDio(_dio(409, 'CALL_NOT_ALLOWED'));
      await h.controller.startCall(CallKind.food, 'order-1');
      expect(h.container.read(callRefusedOrdersProvider), {'order-1'});
    });

    test('a refused microphone never rings the driver', () async {
      h.micRefused = true;
      expect(
        await h.controller.startCall(CallKind.food, 'order-1'),
        CallError.microphone,
      );
      expect(h.repo.calls, isEmpty);
    });

    test('hanging up while it rings cancels it', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      await h.controller.hangUp();
      await _settle();
      expect(h.repo.calls.last, 'end call-1');
      expect(h.session!.phase, CallPhase.ended);
      expect(h.session!.endReason, 'cancelled');
      expect(h.media.closed, isTrue);
      expect(h.systemUi.log.last, 'end call-1');

      // CallKit echoes the end back: not a second hang-up.
      h.systemUi.eventCtl.add(const SystemCallEnded('call-1'));
      await _settle();
      expect(h.repo.calls.where((c) => c.startsWith('end')), hasLength(1));
    });

    test('call_ended from the server closes it with its reason', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      h.frame({
        'type': 'call_ended',
        'call': _view(status: 'ended', endReason: 'missed'),
      });
      await _settle();
      expect(h.session!.phase, CallPhase.ended);
      expect(h.session!.endReason, 'missed');
      expect(h.repo.calls, ['start food order-1'], reason: 'no end request');
    });

    test('CALL_SIGNAL_REJECTED tears the call down', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      h.frame({
        'type': 'error',
        'code': 'CALL_SIGNAL_REJECTED',
        'data': 'call ended',
      });
      await _settle();
      expect(h.session!.phase, CallPhase.ended);
    });

    test('a network switch mid-call renegotiates with iceRestart', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      h.frame({'type': 'call_accepted', 'call': _view(status: 'accepted')});
      await _settle();
      h.signal('answer', {'type': 'answer', 'sdp': 'a'});
      h.media.stateCtl.add(CallMediaState.connected);
      await _settle();
      h.network.add(null);
      await _settle();
      expect(h.media.log.last, 'offer restart');
      expect(h.signaling.signals.last, 'offer');
    });

    test('mute and speaker reach the audio', () async {
      await h.controller.startCall(CallKind.food, 'order-1');
      await h.controller.toggleMute();
      await h.controller.toggleSpeaker();
      expect(h.session!.muted, isTrue);
      expect(h.session!.speaker, isTrue);
      expect(h.media.log, containsAll(['muted true', 'speaker true']));
    });
  });

  group('the driver calls', () {
    late _Harness h;
    setUp(() => h = _Harness());
    tearDown(() => h.dispose());

    test('call_incoming rings; accept answers the offer', () async {
      h.frame({'type': 'call_incoming', 'call': _view(direction: 'incoming')});
      await _settle();
      expect(h.session!.phase, CallPhase.incoming);
      expect(h.screenOpened, 1);

      // The offer can land before the accept request returns.
      h.repo.acceptGate = Completer();
      final accepting = h.controller.accept();
      await _settle();
      h.signal('ice', {
        'candidate': 'early',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });
      h.signal('offer', {'type': 'offer', 'sdp': 'o'});
      await _settle();
      expect(h.signaling.sent, isEmpty);
      h.repo.acceptGate!.complete();
      await accepting;
      await _settle();

      expect(h.repo.calls, ['accept call-1']);
      expect(h.media.log, [
        'mic',
        'connect',
        'muted false',
        'remote offer',
        'candidate early',
        'answer',
      ]);
      expect(h.signaling.signals, ['answer']);
      expect(h.session!.phase, CallPhase.connecting);
      expect(
        h.systemUi.log,
        contains('outgoing call-1'),
        reason: 'answered on our screen: the system holds the call too',
      );
    });

    test('declining tells the backend', () async {
      h.frame({'type': 'call_incoming', 'call': _view(direction: 'incoming')});
      await _settle();
      await h.controller.decline();
      expect(h.repo.calls, ['decline call-1']);
      expect(h.session!.endReason, 'declined');
    });

    test('it stopped ringing before the answer (409 CALL_ENDED)', () async {
      h.frame({'type': 'call_incoming', 'call': _view(direction: 'incoming')});
      await _settle();
      h.repo.acceptError = CallException.fromDio(_dio(409, 'CALL_ENDED'));
      await h.controller.accept();
      expect(h.session!.phase, CallPhase.ended);
      expect(h.session!.endReason, 'missed');
    });

    test('answered on the lock screen before the app knew', () async {
      h.systemUi.eventCtl.add(
        const SystemCallAccepted('call-1', {
          'type': 'call_incoming',
          'call_id': 'call-1',
          'kind': 'food',
          'job_id': 'order-1',
          'caller_name': 'สมชาย',
          'ring_timeout_sec': '30',
        }),
      );
      await _settle();
      expect(h.repo.calls, ['accept call-1']);
      expect(h.session!.call.kind, CallKind.food);
      expect(h.session!.phase, CallPhase.connecting);
      expect(h.screenOpened, 1);
      expect(
        h.systemUi.log,
        isNot(contains('outgoing call-1')),
        reason: 'CallKit already holds it',
      );
    });

    test('declined in the system UI with no session', () async {
      h.systemUi.eventCtl.add(const SystemCallDeclined('call-7'));
      await _settle();
      expect(h.repo.calls, ['decline call-7']);
    });

    test('a call_ended push stops a call still ringing in CallKit', () async {
      h.controller.onRemoteEnded('call-5', 'cancelled');
      await _settle();
      expect(h.systemUi.log, ['end call-5']);
      expect(h.session, isNull);
    });

    test('a replayed offer is answered once; a new one again', () async {
      h.frame({'type': 'call_incoming', 'call': _view(direction: 'incoming')});
      await _settle();
      await h.controller.accept();
      h.signal('offer', {'type': 'offer', 'sdp': 'o'});
      await _settle();
      // The socket reconnected: the server replays the same offer.
      h.signal('offer', {'type': 'offer', 'sdp': 'o'});
      await _settle();
      expect(h.signaling.signals, ['answer']);
      expect(h.media.log.where((l) => l == 'remote offer'), hasLength(1));

      // The driver renegotiates (network switch): a new offer is answered.
      h.signal('offer', {'type': 'offer', 'sdp': 'o2'});
      await _settle();
      expect(h.signaling.signals, ['answer', 'answer']);
    });

    test('a pushed call that no longer rings is not shown', () async {
      h.repo.calls.clear();
      await h.controller.onIncomingPush({
        'type': 'call_incoming',
        'call_id': 'call-1',
        'kind': 'food',
        'job_id': 'order-1',
      });
      expect(h.repo.calls, ['get call-1']);
      expect(h.session!.phase, CallPhase.incoming);
    });
  });

  group('iPhone woken by PushKit', () {
    final ringing = (
      callId: 'call-1',
      accepted: false,
      extra: <String, dynamic>{
        'type': 'call_incoming',
        'call_id': 'call-1',
        'kind': 'food',
        'job_id': 'order-1',
        'ring_timeout_sec': '30',
      },
    );
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('CallKit rings it: the app follows, without its own screen', () async {
      final h = _Harness();
      h.systemUi.active = [ringing];
      h.systemUi.eventCtl.add(SystemCallIncoming('call-1', ringing.extra));
      await _settle();
      expect(h.repo.calls, ['get call-1']);
      expect(h.session!.phase, CallPhase.incoming);
      expect(h.screenOpened, 0, reason: 'CallKit is the incoming screen');
      h.dispose();
    });

    test('ringing before the app listened: picked up at start', () async {
      final h = _Harness(systemCalls: [ringing]);
      await _settle();
      expect(h.repo.calls, ['get call-1']);
      expect(h.session!.phase, CallPhase.incoming);
      h.dispose();
    });
  });

  group('timers', () {
    testWidgets('a ringing call the caller cancelled stops (polled)', (
      tester,
    ) async {
      final h = _Harness();
      h.frame({'type': 'call_incoming', 'call': _view(direction: 'incoming')});
      await tester.pump();
      expect(h.session!.phase, CallPhase.incoming);
      await tester.pump(CallController.ringPollInterval);
      expect(h.session!.phase, CallPhase.incoming, reason: 'still ringing');

      h.repo.getView = () =>
          _view(direction: 'incoming', status: 'ended', endReason: 'cancelled');
      await tester.pump(CallController.ringPollInterval);
      await tester.pump();
      expect(h.session!.phase, CallPhase.ended);
      expect(h.session!.endReason, 'cancelled');
      expect(h.systemUi.log.last, 'end call-1');
      await tester.pump(CallController.endedLinger);
      h.dispose();
    });

    testWidgets('an unanswered call ends itself past the ring timeout', (
      tester,
    ) async {
      final h = _Harness();
      unawaited(h.controller.startCall(CallKind.food, 'order-1'));
      await tester.pump();
      expect(h.session!.phase, CallPhase.outgoing);
      await tester.pump(const Duration(seconds: 36));
      expect(h.repo.calls.last, 'end call-1');
      expect(h.session!.endReason, 'missed');
      await tester.pump(CallController.endedLinger);
      expect(h.session, isNull);
      h.dispose();
    });

    testWidgets('audio that never connects ends as failed', (tester) async {
      final h = _Harness();
      unawaited(h.controller.startCall(CallKind.food, 'order-1'));
      await tester.pump();
      h.frame({'type': 'call_accepted', 'call': _view(status: 'accepted')});
      await tester.pump();
      await tester.pump(CallController.connectTimeout);
      expect(h.repo.calls.last, 'end call-1 failed');
      expect(h.session!.endReason, 'failed');
      await tester.pump(CallController.endedLinger);
      h.dispose();
    });
  });
}
