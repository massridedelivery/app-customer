import 'dart:async';

import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// What the phone's own call UI (CallKit / the Android incoming screen)
/// reports back.
sealed class SystemCallEvent {
  const SystemCallEvent(this.callId);

  final String callId;
}

/// Ringing in the system UI. On an iPhone this is how the app hears of a call
/// whose PushKit push woke it.
class SystemCallIncoming extends SystemCallEvent {
  const SystemCallIncoming(super.callId, this.extra);

  /// What the call was shown with (the push data).
  final Map<String, dynamic> extra;
}

/// Answered from the lock screen, the CallKit banner or the Android screen.
class SystemCallAccepted extends SystemCallEvent {
  const SystemCallAccepted(super.callId, this.extra);

  /// What the call was shown with (the push data).
  final Map<String, dynamic> extra;
}

class SystemCallDeclined extends SystemCallEvent {
  const SystemCallDeclined(super.callId);
}

/// Hung up from the system UI (or it rang out there).
class SystemCallEnded extends SystemCallEvent {
  const SystemCallEnded(super.callId);
}

class SystemCallMuted extends SystemCallEvent {
  const SystemCallMuted(super.callId, this.muted);

  final bool muted;
}

/// PushKit handed out a new VoIP token (iOS).
class SystemVoipTokenChanged extends SystemCallEvent {
  const SystemVoipTokenChanged() : super('');
}

/// The phone's own call UI. On iOS every call goes through CallKit, which is
/// what keeps the app (and its audio) alive in the background; on Android the
/// plugin runs a self-managed ConnectionService with a full-screen incoming
/// screen and a foreground service while the call is on.
abstract class CallSystemUi {
  Stream<SystemCallEvent> get events;

  /// Shows a ringing incoming call.
  Future<void> showIncoming(CallView call, {Map<String, dynamic>? extra});

  /// Reports an outgoing call (iOS: so the call survives the background).
  Future<void> startOutgoing(CallView call);

  /// The audio connected.
  Future<void> setConnected(String callId);

  Future<void> end(String callId);

  /// Calls the system UI has: an accepted one is a call answered while the
  /// app was not running.
  Future<List<({String callId, bool accepted, Map<String, dynamic> extra})>>
  activeCalls();

  /// The PushKit token, in hex (iOS only).
  Future<String?> voipToken();
}

class CallKitSystemUi implements CallSystemUi {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Stream<SystemCallEvent> get events {
    if (!_supported) return const Stream.empty();
    return FlutterCallkitIncoming.onEvent
        .map<SystemCallEvent?>((event) {
          return switch (event) {
            CallEventActionCallIncoming(:final callKitParams) =>
              SystemCallIncoming(
                callKitParams.id,
                Map<String, dynamic>.from(callKitParams.extra ?? const {}),
              ),
            CallEventActionCallAccept(:final callKitParams) =>
              SystemCallAccepted(
                callKitParams.id,
                Map<String, dynamic>.from(callKitParams.extra ?? const {}),
              ),
            CallEventActionCallDecline(:final callKitParams) =>
              SystemCallDeclined(callKitParams.id),
            CallEventActionCallEnded(:final callKitParams) => SystemCallEnded(
              callKitParams.id,
            ),
            CallEventActionCallTimeout(:final id) => SystemCallEnded(id),
            CallEventActionCallToggleMute(:final id, :final isMuted) =>
              SystemCallMuted(id, isMuted),
            CallEventActionDidUpdateDevicePushTokenVoip() =>
              const SystemVoipTokenChanged(),
            _ => null,
          };
        })
        .where((e) => e != null)
        .cast<SystemCallEvent>();
  }

  @override
  Future<void> showIncoming(CallView call, {Map<String, dynamic>? extra}) {
    if (!_supported) return Future.value();
    return FlutterCallkitIncoming.showCallkitIncoming(
      callKitParams(call, extra: extra),
    );
  }

  @override
  Future<void> startOutgoing(CallView call) {
    if (!_supported) return Future.value();
    return FlutterCallkitIncoming.startCall(callKitParams(call));
  }

  @override
  Future<void> setConnected(String callId) {
    if (!_supported) return Future.value();
    return FlutterCallkitIncoming.setCallConnected(callId);
  }

  @override
  Future<void> end(String callId) {
    if (!_supported) return Future.value();
    return FlutterCallkitIncoming.endCall(callId);
  }

  @override
  Future<List<({String callId, bool accepted, Map<String, dynamic> extra})>>
  activeCalls() async {
    if (!_supported) return const [];
    final calls = await FlutterCallkitIncoming.activeCalls();
    return [
      for (final c in calls)
        (
          callId: c.id,
          accepted: c.isAccepted,
          extra: Map<String, dynamic>.from(c.extra ?? const {}),
        ),
    ];
  }

  @override
  Future<String?> voipToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) return null;
    final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    return token is String && token.isNotEmpty ? token : null;
  }
}

/// How a call is shown in CallKit / on the Android incoming screen. The push
/// data rides along in `extra`, so a call answered while the app was not
/// running still knows its order.
CallKitParams callKitParams(CallView call, {Map<String, dynamic>? extra}) {
  final name = call.peer.fullName.isNotEmpty ? call.peer.fullName : 'ไรเดอร์';
  return CallKitParams(
    id: call.callId,
    nameCaller: name,
    appName: 'Mass Move',
    avatar: call.peer.avatarUrl,
    handle: name,
    type: 0, // audio
    duration: call.ringTimeoutSec * 1000,
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'สายที่ไม่ได้รับ',
    ),
    callingNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'กำลังโทร…',
    ),
    extra: {
      'type': 'call_incoming',
      'call_id': call.callId,
      'kind': call.kind.name,
      'job_id': call.jobId,
      'caller_name': call.peer.fullName,
      'caller_role': call.peer.role,
      if (call.peer.avatarUrl != null) 'caller_avatar': call.peer.avatarUrl,
      'ring_timeout_sec': '${call.ringTimeoutSec}',
      ...?extra,
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      backgroundColor: '#0F7B4A',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      incomingCallNotificationChannelName: 'สายเรียกเข้า',
      missedCallNotificationChannelName: 'สายที่ไม่ได้รับ',
      isShowFullLockedScreen: true,
      isImportant: true,
      isFullScreen: true,
      textAccept: 'รับสาย',
      textDecline: 'ปฏิเสธ',
    ),
    ios: const IOSParams(
      handleType: 'generic',
      supportsVideo: false,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
      includesCallsInRecents: false,
      configureAudioSession: true,
      audioSessionMode: 'voiceChat',
    ),
  );
}
