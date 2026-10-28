import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/call/data/call_media.dart';
import 'package:customer_app/features/call/data/call_repository.dart';
import 'package:customer_app/features/call/data/call_signaling.dart';
import 'package:customer_app/features/call/data/call_system_ui.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a call is, from this phone's side.
enum CallPhase {
  /// We rang the driver; waiting for them to answer.
  outgoing,

  /// The driver is ringing us.
  incoming,

  /// Answered; the audio is being set up.
  connecting,

  /// Talking.
  active,

  /// Over (shown for a moment before the screen closes).
  ended,
}

class CallSession {
  const CallSession({
    required this.call,
    required this.phase,
    this.muted = false,
    this.speaker = false,
    this.connectedAt,
    this.endReason,
  });

  final CallView call;
  final CallPhase phase;
  final bool muted;
  final bool speaker;

  /// When the audio first connected: the call timer counts from here.
  final DateTime? connectedAt;

  /// Why it ended: the backend's `end_reason` (`hangup`, `declined`,
  /// `missed`, `cancelled`, `failed`, `lost`), or `busy` / `blocked` /
  /// `not_allowed` / `microphone` when it never got going.
  final String? endReason;

  String get callId => call.callId;

  CallSession copyWith({
    CallView? call,
    CallPhase? phase,
    bool? muted,
    bool? speaker,
    DateTime? connectedAt,
    String? endReason,
  }) => CallSession(
    call: call ?? this.call,
    phase: phase ?? this.phase,
    muted: muted ?? this.muted,
    speaker: speaker ?? this.speaker,
    connectedAt: connectedAt ?? this.connectedAt,
    endReason: endReason ?? this.endReason,
  );
}

/// A new WebRTC peer for each call.
final callMediaFactoryProvider = Provider<CallMedia Function()>(
  (ref) => WebRtcCallMedia.new,
);

final callSystemUiProvider = Provider<CallSystemUi>((ref) => CallKitSystemUi());

/// Fires when the phone switches network (Wi-Fi ↔ 4G), so the caller can
/// renegotiate.
final callNetworkChangesProvider = Provider<Stream<void>>((ref) {
  if (kIsWeb) return const Stream.empty();
  return Connectivity().onConnectivityChanged
      .map((r) => r.toSet())
      .distinct((a, b) => setEquals(a, b));
});

/// Opens the call screen (once).
final callScreenOpenerProvider = Provider<void Function()>((ref) {
  return () {
    final router = ref.read(routerProvider);
    if (router.state.uri.path != '/call') router.push('/call');
  };
});

/// `GET /api/calls/settings`, re-read on every login. Off when it can't be
/// read: no Call button is better than one that fails.
final callSettingsProvider = FutureProvider<CallSettings>((ref) async {
  final loggedIn = ref.watch(
    authControllerProvider.select((s) => s.isAuthenticated),
  );
  if (!loggedIn) return const CallSettings();
  try {
    return await ref.read(callRepositoryProvider).settings();
  } catch (e) {
    debugPrint('Call: settings failed (calling off): $e');
    return const CallSettings();
  }
});

/// Orders whose Call button was refused by the backend (409
/// CALL_NOT_ALLOWED): no longer callable, so the button goes.
final callRefusedOrdersProvider =
    NotifierProvider<CallRefusedOrders, Set<String>>(CallRefusedOrders.new);

class CallRefusedOrders extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String jobId) => state = {...state, jobId};
}

final callControllerProvider = NotifierProvider<CallController, CallSession?>(
  CallController.new,
);

/// Runs the one call this phone can be on: rings, answers, and carries the
/// WebRTC handshake over the socket (backend "In-App Calling").
///
/// The caller sends the offer only after `call_accepted`; the callee answers
/// the offer it receives; both trickle ICE candidates, and a candidate that
/// arrives before the remote description waits. Media work runs one step at a
/// time ([_enqueue]) so frames that race the setup (the offer can land before
/// the accept request returns) are applied in order.
class CallController extends Notifier<CallSession?> {
  /// Ring budget past the server's: the server ends a missed call itself
  /// (`call_ended`), this only covers a lost frame.
  static const ringGrace = Duration(seconds: 5);

  /// How long the audio gets to connect, after an answer or after it drops.
  static const connectTimeout = Duration(seconds: 15);

  /// How long an ended call stays on screen.
  static const endedLinger = Duration(milliseconds: 1500);

  /// How often a call ringing on this phone is re-read (see
  /// [_pollWhileRinging]).
  static const ringPollInterval = Duration(milliseconds: 2500);

  CallMedia? _media;
  Completer<void>? _mediaReady;
  Future<void> _ops = Future.value();
  bool _remoteSet = false;
  final List<Map<String, dynamic>> _pendingCandidates = [];

  /// The other phone's descriptions already applied. The server replays a
  /// party's signals when its socket reconnects, so the same offer (or
  /// answer) can arrive twice; a renegotiation brings a new one.
  final Set<String> _remoteSdps = {};

  Timer? _ringTimer;
  Timer? _ringPoll;
  Timer? _connectTimer;
  Timer? _clearTimer;
  final List<StreamSubscription<Object?>> _subs = [];
  StreamSubscription<Map<String, dynamic>>? _candidateSub;
  StreamSubscription<CallMediaState>? _mediaStateSub;

  /// Calls this phone ended itself, so the system UI's echo of that end is
  /// not taken as the user hanging up again.
  final Set<String> _closedHere = {};

  bool _started = false;

  CallRepository get _repo => ref.read(callRepositoryProvider);
  CallSignaling get _signaling => ref.read(callSignalingProvider);
  CallSystemUi get _systemUi => ref.read(callSystemUiProvider);

  @override
  CallSession? build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _cancelTimers();
      _clearTimer?.cancel();
      _closeMedia();
    });
    return null;
  }

  /// Starts listening to the socket, the system call UI and the network.
  /// Called once at app start, before any widget, so a call answered on a
  /// locked phone is picked up even when the app was not running.
  void start() {
    if (_started) return;
    _started = true;
    _subs
      ..add(_signaling.frames.listen(_onFrame))
      ..add(_systemUi.events.listen(_onSystemEvent))
      ..add(ref.read(callNetworkChangesProvider).listen((_) => _onNetwork()));
    unawaited(_resumeAnsweredCall());
  }

  // ─── Placing a call ────────────────────────────────────────────────────

  /// Rings the driver of an order. Returns why it couldn't, or null once it
  /// is ringing (the call screen is then open).
  Future<CallError?> startCall(CallKind kind, String jobId) async {
    if (state != null && state!.phase != CallPhase.ended) return null;
    final media = ref.read(callMediaFactoryProvider)();
    // The microphone permission is asked here, on the first call, and a
    // refusal stops before the driver's phone rings.
    try {
      await media.openMicrophone();
    } catch (e) {
      debugPrint('Call: microphone refused: $e');
      await media.close();
      return CallError.microphone;
    }
    await _signaling.connect();

    final CallView call;
    try {
      call = await _repo.start(kind, jobId);
    } on CallException catch (e) {
      await media.close();
      if (e.error == CallError.notAllowed) {
        ref.read(callRefusedOrdersProvider.notifier).add(jobId);
      }
      if (e.error == CallError.disabled) ref.invalidate(callSettingsProvider);
      return e.error;
    } catch (e) {
      await media.close();
      return CallError.failed;
    }

    _beginSession(call, CallPhase.outgoing, media);
    unawaited(_systemUi.startOutgoing(call));
    _ringTimer = Timer(Duration(seconds: call.ringTimeoutSec) + ringGrace, () {
      if (state?.phase == CallPhase.outgoing) hangUp(reason: 'missed');
    });
    ref.read(callScreenOpenerProvider)();
    return null;
  }

  // ─── Receiving a call ──────────────────────────────────────────────────

  /// A ringing call reached this phone (socket frame or push) while the app
  /// is running: show the incoming screen. On an iPhone the VoIP push has
  /// usually put it in CallKit already; then CallKit's banner is the incoming
  /// screen and ours opens once it is answered.
  Future<void> _ring(CallView call) async {
    if (state != null && state!.phase != CallPhase.ended) return;
    if (_closedHere.contains(call.callId)) return;
    _beginSession(call, CallPhase.incoming, null);
    _ringTimer = Timer(Duration(seconds: call.ringTimeoutSec) + ringGrace, () {
      if (state?.phase == CallPhase.incoming) _teardown('missed');
    });
    _pollWhileRinging(call.callId);
    // An iPhone woken by PushKit has no socket yet: `call_ended` and, once
    // answered, the caller's offer come over it.
    unawaited(_signaling.connect());
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _inSystemUi(call.callId)) {
      return;
    }
    if (state?.callId == call.callId && state!.phase == CallPhase.incoming) {
      ref.read(callScreenOpenerProvider)();
    }
  }

  /// Whether CallKit shows [callId], allowing the PushKit push a moment to
  /// arrive after the socket frame.
  Future<bool> _inSystemUi(String callId) async {
    for (var i = 0; i < 4; i++) {
      try {
        final calls = await _systemUi.activeCalls();
        if (calls.any((c) => c.callId == callId)) return true;
      } catch (_) {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// Re-reads a call ringing on this phone until it is answered or stops.
  /// There is no VoIP push for `call_ended` (Apple counts every VoIP push as a
  /// new call), so an iPhone woken by PushKit hears of the caller hanging up
  /// only over a socket that may not be up yet; and a lost frame would leave
  /// any phone ringing until the ring timer.
  void _pollWhileRinging(String callId) {
    bool ringing() =>
        state?.callId == callId && state!.phase == CallPhase.incoming;
    _ringPoll?.cancel();
    _ringPoll = Timer.periodic(ringPollInterval, (timer) async {
      if (!ringing()) {
        timer.cancel();
        return;
      }
      try {
        final call = await _repo.get(callId);
        // Answered on another of the user's phones, or over.
        if (!call.isRinging && ringing()) {
          onRemoteEnded(callId, call.endReason ?? 'hangup');
        }
      } catch (e) {
        debugPrint('Call: ringing call unreadable: $e');
      }
    });
  }

  /// A `call_incoming` push the app handles itself (the app was open, or a
  /// notification was tapped): checks it still rings first.
  Future<void> onIncomingPush(Map<String, dynamic> data) async {
    final pushed = CallView.fromPush(data);
    if (pushed == null || state?.callId == pushed.callId) return;
    try {
      final call = await _repo.get(pushed.callId);
      if (call.isRinging) await _ring(call);
    } catch (e) {
      debugPrint('Call: pushed call unreadable: $e');
    }
  }

  /// Answers the ringing call. [fromSystem] when it was answered in CallKit
  /// or on the Android incoming screen, which then already hold the call.
  Future<void> accept({bool fromSystem = false}) async {
    final session = state;
    if (session == null || session.phase != CallPhase.incoming) return;
    _ringTimer?.cancel();
    _ringPoll?.cancel();
    state = session.copyWith(phase: CallPhase.connecting);
    ref.read(callScreenOpenerProvider)();

    final media = ref.read(callMediaFactoryProvider)();
    _media = media;
    _watchMedia(media);
    try {
      await media.openMicrophone();
    } catch (e) {
      debugPrint('Call: microphone refused: $e');
      unawaited(_quietly(() => _repo.decline(session.callId)));
      _teardown('microphone');
      return;
    }
    // The caller's offer comes over the socket the moment we accept.
    await _signaling.connect();

    final CallView answered;
    try {
      answered = await _repo.accept(session.callId);
    } on CallException catch (e) {
      _teardown(e.error == CallError.ended ? 'missed' : 'failed');
      return;
    } catch (_) {
      _teardown('failed');
      return;
    }
    if (state?.callId != session.callId) return;
    state = state!.copyWith(
      call: session.call.copyWith(
        status: 'accepted',
        iceServers: answered.iceServers,
      ),
    );
    // Answered on our own screen: hand the call to the system too. That is
    // what keeps it going in the background (Android's foreground service),
    // and on iOS CallKit's audio session is what starts WebRTC's audio.
    if (!fromSystem) unawaited(_systemUi.startOutgoing(state!.call));
    await _connectMedia(answered.iceServers);
  }

  /// Turns the ringing call down.
  Future<void> decline() async {
    final session = state;
    if (session == null || session.phase != CallPhase.incoming) return;
    unawaited(_quietly(() => _repo.decline(session.callId)));
    _teardown('declined');
  }

  // ─── In the call ───────────────────────────────────────────────────────

  /// Hangs up, or cancels a call still ringing on the driver's phone.
  Future<void> hangUp({String reason = 'hangup', bool failed = false}) async {
    final session = state;
    if (session == null || session.phase == CallPhase.ended) return;
    if (session.phase == CallPhase.incoming) return decline();
    unawaited(_quietly(() => _repo.end(session.callId, failed: failed)));
    _teardown(
      session.phase == CallPhase.outgoing && reason == 'hangup'
          ? 'cancelled'
          : reason,
    );
  }

  Future<void> toggleMute() async {
    final session = state;
    if (session == null) return;
    final muted = !session.muted;
    state = session.copyWith(muted: muted);
    await _media?.setMuted(muted);
  }

  Future<void> toggleSpeaker() async {
    final session = state;
    if (session == null) return;
    final speaker = !session.speaker;
    state = session.copyWith(speaker: speaker);
    await _media?.setSpeaker(speaker);
  }

  // ─── Socket ────────────────────────────────────────────────────────────

  void _onFrame(Map<String, dynamic> frame) {
    final type = frame['type'];
    switch (type) {
      case 'call_incoming':
        final call = _callOf(frame);
        if (call != null && call.isRinging) unawaited(_ring(call));
      case 'call_accepted':
        final call = _callOf(frame);
        if (call != null && call.callId == state?.callId) _onAccepted();
      case 'call_ended':
        final call = _callOf(frame);
        if (call != null) onRemoteEnded(call.callId, call.endReason);
      case 'call_signal':
        if (frame['call_id'] == state?.callId) _onSignal(frame);
      case 'error':
        if (frame['code'] == 'CALL_SIGNAL_REJECTED' && state != null) {
          debugPrint('Call: signal rejected: ${frame['data']}');
          _teardown(state!.endReason ?? 'failed');
        }
    }
  }

  CallView? _callOf(Map<String, dynamic> frame) {
    final call = frame['call'];
    return call is Map ? CallView.fromJson(Map.from(call)) : null;
  }

  /// The other phone (or the server) ended the call: `call_ended` on the
  /// socket, or the Android `call_ended` push.
  void onRemoteEnded(String callId, String? reason) {
    if (state?.callId == callId) {
      _teardown(reason ?? 'hangup', remote: true);
    } else {
      // Still ringing in the system UI with the app in the background.
      _closedHere.add(callId);
      unawaited(_quietly(() => _systemUi.end(callId)));
    }
  }

  /// The driver answered: the caller makes the offer.
  void _onAccepted() {
    final session = state;
    if (session == null || session.phase != CallPhase.outgoing) return;
    _ringTimer?.cancel();
    state = session.copyWith(phase: CallPhase.connecting);
    _connectMedia(session.call.iceServers, media: _media).then((_) {
      _enqueue(() async {
        final offer = await _media!.createOffer();
        _sendSignal('offer', offer);
      });
    });
  }

  void _onSignal(Map<String, dynamic> frame) {
    final kind = frame['kind'];
    final payload = frame['payload'];
    if (payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);
    final sdp = data['sdp'];
    if ((kind == 'offer' || kind == 'answer') &&
        sdp is String &&
        !_remoteSdps.add(sdp)) {
      return;
    }
    switch (kind) {
      case 'offer':
        _enqueue(() async {
          await _media!.setRemoteDescription(data);
          _remoteSet = true;
          await _flushCandidates();
          final answer = await _media!.createAnswer();
          _sendSignal('answer', answer);
        });
      case 'answer':
        _enqueue(() async {
          await _media!.setRemoteDescription(data);
          _remoteSet = true;
          await _flushCandidates();
        });
      case 'ice':
        _enqueue(() async {
          if (_remoteSet) {
            await _media!.addCandidate(data);
          } else {
            _pendingCandidates.add(data);
          }
        });
    }
  }

  Future<void> _flushCandidates() async {
    final queued = List.of(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in queued) {
      await _media!.addCandidate(c);
    }
  }

  void _sendSignal(String kind, Map<String, dynamic> payload) {
    final callId = state?.callId;
    if (callId == null) return;
    _signaling.send({
      'type': 'call_signal',
      'call_id': callId,
      'kind': kind,
      'payload': payload,
    });
  }

  // ─── Media ─────────────────────────────────────────────────────────────

  /// Creates the peer connection; queued signal work waits for it.
  Future<void> _connectMedia(
    List<Map<String, dynamic>> iceServers, {
    CallMedia? media,
  }) async {
    final m = media ?? _media!;
    final ready = _mediaReady;
    _armConnectTimer();
    try {
      await m.connect(iceServers);
      await m.setMuted(state?.muted ?? false);
      if (ready != null && !ready.isCompleted) ready.complete();
    } catch (e) {
      debugPrint('Call: peer connection failed: $e');
      if (ready != null && !ready.isCompleted) ready.completeError(e);
      hangUp(reason: 'failed', failed: true);
    }
  }

  void _watchMedia(CallMedia media) {
    _candidateSub?.cancel();
    _mediaStateSub?.cancel();
    _candidateSub = media.candidates.listen((c) => _sendSignal('ice', c));
    _mediaStateSub = media.states.listen(_onMediaState);
  }

  void _onMediaState(CallMediaState s) {
    final session = state;
    if (session == null || session.phase == CallPhase.ended) return;
    switch (s) {
      case CallMediaState.connected:
        _connectTimer?.cancel();
        if (session.phase != CallPhase.active) {
          state = session.copyWith(
            phase: CallPhase.active,
            connectedAt: session.connectedAt ?? DateTime.now(),
          );
          unawaited(_quietly(() => _systemUi.setConnected(session.callId)));
        }
      case CallMediaState.disconnected || CallMediaState.failed:
        if (session.phase == CallPhase.active) {
          // Dropped mid-call: the caller renegotiates; either side gives it
          // [connectTimeout] to come back.
          _restartIce();
          _armConnectTimer();
        } else if (s == CallMediaState.failed) {
          hangUp(reason: 'failed', failed: true);
        }
      case CallMediaState.connecting:
        break;
    }
  }

  /// A network switch: the caller renegotiates with a fresh offer.
  void _onNetwork() {
    final phase = state?.phase;
    if (phase == CallPhase.active || phase == CallPhase.connecting) {
      _restartIce();
    }
  }

  void _restartIce() {
    final session = state;
    if (session == null || session.call.isIncoming || !_remoteSet) return;
    _enqueue(() async {
      final offer = await _media!.createOffer(iceRestart: true);
      _sendSignal('offer', offer);
    });
  }

  void _armConnectTimer() {
    _connectTimer?.cancel();
    _connectTimer = Timer(connectTimeout, () {
      final phase = state?.phase;
      if (phase == CallPhase.connecting || phase == CallPhase.active) {
        hangUp(reason: 'failed', failed: true);
      }
    });
  }

  /// Runs [op] after the media is up and after the work queued before it.
  void _enqueue(Future<void> Function() op) {
    final ready = _mediaReady;
    if (ready == null) return;
    _ops = _ops.then((_) async {
      try {
        await ready.future;
        if (_media == null) return;
        await op();
      } catch (e) {
        debugPrint('Call: media step failed: $e');
      }
    });
  }

  // ─── System call UI (CallKit / Android) ───────────────────────────────

  void _onSystemEvent(SystemCallEvent event) {
    final session = state;
    final ours = session != null && session.callId == event.callId;
    switch (event) {
      case SystemCallIncoming(:final extra):
        // An iPhone woken by PushKit: CallKit rings, and the app learns of
        // the call here.
        if (!ours && defaultTargetPlatform == TargetPlatform.iOS) {
          unawaited(onIncomingPush(extra));
        }
      case SystemCallAccepted(:final extra):
        if (ours) {
          accept(fromSystem: true);
        } else if (session == null || session.phase == CallPhase.ended) {
          final call = CallView.fromPush(extra);
          if (call != null) _answerFromSystem(call);
        }
      case SystemCallDeclined():
        if (ours) {
          decline();
        } else if (session == null) {
          unawaited(_quietly(() => _repo.decline(event.callId)));
        }
      case SystemCallEnded():
        if (_closedHere.remove(event.callId)) return;
        if (ours) hangUp();
      case SystemCallMuted(:final muted):
        if (ours && session.muted != muted) toggleMute();
      case SystemVoipTokenChanged():
        break; // VoipTokenRegistrar re-registers it.
    }
  }

  /// A call answered in the system UI before the app knew about it (the app
  /// was closed or in the background).
  void _answerFromSystem(CallView call) {
    _beginSession(call, CallPhase.incoming, null);
    accept(fromSystem: true);
  }

  /// At launch: a call answered on the Android full-screen (or CallKit) UI
  /// that started the app, or one still ringing in CallKit whose PushKit
  /// push woke the app before it was listening.
  Future<void> _resumeAnsweredCall() async {
    try {
      final calls = await _systemUi.activeCalls();
      for (final c in calls) {
        if (state != null) break;
        if (c.accepted) {
          final call = CallView.fromPush(c.extra);
          if (call != null) _answerFromSystem(call);
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          await onIncomingPush(c.extra);
        }
      }
    } catch (e) {
      debugPrint('Call: active calls unreadable: $e');
    }
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  void _beginSession(CallView call, CallPhase phase, CallMedia? media) {
    _clearTimer?.cancel();
    _cancelTimers();
    _closeMedia();
    _remoteSet = false;
    _pendingCandidates.clear();
    _remoteSdps.clear();
    _ops = Future.value();
    _mediaReady = Completer<void>();
    _media = media;
    if (media != null) _watchMedia(media);
    state = CallSession(call: call, phase: phase);
  }

  /// Ends the call on this phone: audio, timers, the system UI.
  void _teardown(String reason, {bool remote = false}) {
    final session = state;
    if (session == null || session.phase == CallPhase.ended) return;
    _cancelTimers();
    _closeMedia();
    _closedHere.add(session.callId);
    unawaited(_quietly(() => _systemUi.end(session.callId)));
    _signaling.release();
    state = session.copyWith(phase: CallPhase.ended, endReason: reason);
    _clearTimer = Timer(endedLinger, () {
      if (state?.callId == session.callId) state = null;
    });
  }

  void _cancelTimers() {
    _ringTimer?.cancel();
    _ringPoll?.cancel();
    _connectTimer?.cancel();
  }

  void _closeMedia() {
    final ready = _mediaReady;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(StateError('call ended'));
      ready.future.ignore();
    }
    _candidateSub?.cancel();
    _mediaStateSub?.cancel();
    _candidateSub = null;
    _mediaStateSub = null;
    final media = _media;
    _media = null;
    if (media != null) unawaited(media.close());
  }

  Future<void> _quietly(Future<Object?> Function() op) async {
    try {
      await op();
    } catch (e) {
      debugPrint('Call: ignored failure: $e');
    }
  }
}
