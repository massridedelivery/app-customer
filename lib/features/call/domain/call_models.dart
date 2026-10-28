/// In-app voice calls between the customer and the driver of an order
/// (backend `docs/frontend_integration.md` → "In-App Calling").
library;

/// Which order a call is on. Every call view, frame and push carries it next
/// to `job_id` (the order's id) so the right order screen can be opened.
enum CallKind {
  ride,
  food,
  messenger;

  static CallKind? parse(Object? raw) => switch (raw) {
    'ride' => ride,
    'food' => food,
    'messenger' => messenger,
    _ => null,
  };
}

/// The other side of a call.
class CallPeer {
  const CallPeer({
    this.userId = '',
    this.fullName = '',
    this.avatarUrl,
    this.role = '',
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;

  /// `driver` or `customer`.
  final String role;

  factory CallPeer.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar_url'];
    return CallPeer(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      role: json['role'] as String? ?? '',
    );
  }
}

/// A call as the backend shows it to this user.
class CallView {
  const CallView({
    required this.callId,
    required this.kind,
    required this.jobId,
    this.status = 'ringing',
    this.endReason,
    this.direction = 'outgoing',
    this.peer = const CallPeer(),
    this.iceServers = const [],
    this.ringTimeoutSec = 30,
  });

  final String callId;
  final CallKind kind;
  final String jobId;

  /// `ringing` | `accepted` | `ended`.
  final String status;

  /// When ended: `hangup` · `declined` · `missed` · `cancelled` · `failed` ·
  /// `lost`.
  final String? endReason;

  /// `outgoing` for the caller, `incoming` for the callee.
  final String direction;
  final CallPeer peer;

  /// Goes into `RTCPeerConnection({iceServers})` as it is. Only on the start
  /// and accept responses; the TURN credentials in it last an hour.
  final List<Map<String, dynamic>> iceServers;
  final int ringTimeoutSec;

  bool get isRinging => status == 'ringing';
  bool get isEnded => status == 'ended';
  bool get isIncoming => direction == 'incoming';

  factory CallView.fromJson(Map<String, dynamic> json) {
    final peer = json['peer'];
    final ice = json['ice_servers'];
    final reason = json['end_reason'];
    return CallView(
      callId: json['call_id'] as String? ?? '',
      kind: CallKind.parse(json['kind']) ?? CallKind.ride,
      jobId: json['job_id'] as String? ?? '',
      status: json['status'] as String? ?? 'ringing',
      endReason: reason is String && reason.isNotEmpty ? reason : null,
      direction: json['direction'] as String? ?? 'outgoing',
      peer: peer is Map ? CallPeer.fromJson(Map.from(peer)) : const CallPeer(),
      iceServers: ice is List
          ? [
              for (final s in ice)
                if (s is Map) Map<String, dynamic>.from(s),
            ]
          : const [],
      ringTimeoutSec: _int(json['ring_timeout_sec']) ?? 30,
    );
  }

  /// An incoming call from a push (`call_incoming`): the FCM data, where
  /// every value is a string, or the PushKit JSON.
  static CallView? fromPush(Map<String, dynamic> data) {
    final callId = data['call_id'];
    final kind = CallKind.parse(data['kind'] ?? 'ride');
    if (callId is! String || callId.isEmpty || kind == null) return null;
    final avatar = data['caller_avatar'];
    return CallView(
      callId: callId,
      kind: kind,
      jobId: data['job_id'] as String? ?? '',
      direction: 'incoming',
      peer: CallPeer(
        fullName: data['caller_name'] as String? ?? '',
        avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
        role: data['caller_role'] as String? ?? 'driver',
      ),
      ringTimeoutSec: _int(data['ring_timeout_sec']) ?? 30,
    );
  }

  CallView copyWith({
    String? status,
    String? endReason,
    CallPeer? peer,
    List<Map<String, dynamic>>? iceServers,
  }) => CallView(
    callId: callId,
    kind: kind,
    jobId: jobId,
    status: status ?? this.status,
    endReason: endReason ?? this.endReason,
    direction: direction,
    peer: peer ?? this.peer,
    iceServers: iceServers ?? this.iceServers,
    ringTimeoutSec: ringTimeoutSec,
  );
}

int? _int(Object? v) => switch (v) {
  final int i => i,
  final num n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

/// `GET /api/calls/settings`. No Call button anywhere unless [enabled].
class CallSettings {
  const CallSettings({this.enabled = false, this.ringTimeoutSec = 30});

  final bool enabled;
  final int ringTimeoutSec;

  factory CallSettings.fromJson(Map<String, dynamic> json) => CallSettings(
    enabled: json['enabled'] == true,
    ringTimeoutSec: _int(json['ring_timeout_sec']) ?? 30,
  );
}

/// How long after an order is done its customer and driver can still call.
const callableAfterDone = Duration(hours: 24);

/// Whether an order of [kind] in [status] can be called, per the backend's
/// table: while it runs, and for 24h after it is done ([doneAt]; when that is
/// unknown the backend decides). The backend checks again, so this only
/// decides whether the button shows.
bool isOrderCallable(
  CallKind kind,
  String? status, {
  DateTime? doneAt,
  DateTime? now,
}) {
  final s = (status ?? '').toUpperCase();
  final (running, done) = switch (kind) {
    CallKind.ride => (
      const {'ACCEPTED', 'ARRIVED_AT_PICK_UP', 'PICKED_UP'},
      'COMPLETED',
    ),
    CallKind.food => (
      const {'DRIVER_ASSIGNED', 'DRIVER_PICKED_UP'},
      'DELIVERED',
    ),
    CallKind.messenger => (
      const {'ACCEPTED', 'ARRIVED_AT_PICKUP', 'PICKED_UP'},
      'DELIVERED',
    ),
  };
  if (running.contains(s)) return true;
  if (s != done) return false;
  if (doneAt == null) return true;
  return (now ?? DateTime.now()).difference(doneAt) < callableAfterDone;
}
