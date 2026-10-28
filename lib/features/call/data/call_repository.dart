import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(apiServiceProvider));
});

/// Why a call couldn't be placed or answered, for the Thai message.
enum CallError {
  /// 409 CALL_BUSY: either side is already on a call.
  busy,

  /// 409 CALL_NOT_ALLOWED: no driver yet, cancelled, or done more than 24h
  /// ago. Hide the button.
  notAllowed,

  /// 403 CALL_BLOCKED: one side blocked the other in chat.
  blocked,

  /// 503 CALL_DISABLED: calling is switched off. Hide the button.
  disabled,

  /// 404: not this customer's order (or call).
  notFound,

  /// 409 CALL_ENDED: it stopped ringing before it was answered.
  ended,

  /// The microphone permission was refused.
  microphone,

  /// Network or server trouble.
  failed,
}

class CallException implements Exception {
  const CallException(this.error, [this.cause]);

  final CallError error;
  final Object? cause;

  factory CallException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final code = body is Map ? body['code'] : null;
    return CallException(switch ((status, code)) {
      (_, 'CALL_BUSY') => CallError.busy,
      (_, 'CALL_NOT_ALLOWED') => CallError.notAllowed,
      (_, 'CALL_BLOCKED') => CallError.blocked,
      (_, 'CALL_DISABLED') => CallError.disabled,
      (_, 'CALL_ENDED') => CallError.ended,
      (404, _) => CallError.notFound,
      _ => CallError.failed,
    }, e);
  }

  @override
  String toString() => 'CallException($error, $cause)';
}

/// The REST half of in-app calling; the WebRTC handshake goes over the
/// socket (see `CallController`).
class CallRepository {
  CallRepository(this._apiService);

  final ApiService _apiService;

  Dio get _dio => _apiService.dio;

  /// `GET /api/calls/settings`.
  Future<CallSettings> settings() async {
    final res = await _dio.get('/api/calls/settings');
    return CallSettings.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Rings the driver of the order: `POST …/:id/calls` for the order's kind.
  /// Returns the call view with `ice_servers`.
  Future<CallView> start(CallKind kind, String jobId) => _call(
    () => _dio.post(switch (kind) {
      CallKind.ride => '/api/customer/jobs/$jobId/calls',
      CallKind.food => '/api/food/customer/orders/$jobId/calls',
      CallKind.messenger => '/api/messenger/customer/orders/$jobId/calls',
    }),
  );

  /// `GET /api/calls/:id`, without `ice_servers`.
  Future<CallView> get(String callId) =>
      _call(() => _dio.get('/api/calls/$callId'));

  /// `POST /api/calls/:id/accept`; the view carries `ice_servers`.
  Future<CallView> accept(String callId) =>
      _call(() => _dio.post('/api/calls/$callId/accept'));

  /// `POST /api/calls/:id/decline`.
  Future<CallView> decline(String callId) =>
      _call(() => _dio.post('/api/calls/$callId/decline'));

  /// `POST /api/calls/:id/end`; [failed] when the audio never connected.
  Future<CallView> end(String callId, {bool failed = false}) => _call(
    () => _dio.post(
      '/api/calls/$callId/end',
      data: failed ? {'reason': 'failed'} : null,
    ),
  );

  /// `POST /api/calls/voip-token` (iOS): the PushKit token, in hex.
  /// [bundleId] is this build's: its pushes go to `<bundleId>.voip`, so the
  /// develop and the store app both ring.
  Future<void> registerVoipToken(
    String token, {
    required bool sandbox,
    String? bundleId,
  }) => _dio.post(
    '/api/calls/voip-token',
    data: _voipBody(token, sandbox, bundleId),
  );

  /// `DELETE /api/calls/voip-token`, on logout, with the same body.
  Future<void> unregisterVoipToken(
    String token, {
    required bool sandbox,
    String? bundleId,
  }) => _dio.delete(
    '/api/calls/voip-token',
    data: _voipBody(token, sandbox, bundleId),
  );

  static Map<String, dynamic> _voipBody(
    String token,
    bool sandbox,
    String? bundleId,
  ) => {
    'token': token,
    'sandbox': sandbox,
    if (bundleId != null && bundleId.isNotEmpty) 'bundle_id': bundleId,
  };

  Future<CallView> _call(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      return CallView.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw CallException.fromDio(e);
    }
  }
}
