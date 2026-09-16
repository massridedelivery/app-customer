import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Shared retry layer for transient failures (SCRUM-50).
///
/// The backend degrades gracefully under load: instead of failing hard it sheds
/// a *retryable* `503` (or `429` with `Retry-After`) and is idempotent on
/// money-path creates. That design only reaches the user if the client retries,
/// so this interceptor retries transient failures with exponential backoff +
/// jitter.
///
/// Safety rules:
/// * `GET` / `HEAD` are always safe to replay.
/// * Other verbs are replayed ONLY when the request carries an
///   `Idempotency-Key` header — the backend dedupes those, so a replay returns
///   the original resource instead of a duplicate booking/dispatch/charge.
/// * Genuine client errors (`400` / `409` / `422` / `404` / `401`) are never
///   retried — `401` is owned by the auth-refresh interceptor.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const int _maxRetries = 3;
  static const int _baseDelayMs = 400;
  static const int _maxDelayMs = 6000;
  static const String _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (attempt >= _maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }

    await Future<void>.delayed(_delayFor(err, attempt));
    options.extra[_attemptKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Exhausted or hit a non-retryable status on the replay — surface it.
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return _methodIsSafe(err.requestOptions);
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        if (code == 503 || code == 500 || code == 429) {
          return _methodIsSafe(err.requestOptions);
        }
        return false;
      default:
        return false;
    }
  }

  bool _methodIsSafe(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') return true;
    // A non-idempotent verb is safe to replay only with an Idempotency-Key.
    return options.headers.keys.any(
      (k) => k.toLowerCase() == 'idempotency-key',
    );
  }

  Duration _delayFor(DioException err, int attempt) {
    // Honour Retry-After (integer seconds) on 429 when present.
    if (err.response?.statusCode == 429) {
      final raw = err.response?.headers.value('retry-after');
      final seconds = raw == null ? null : int.tryParse(raw.trim());
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(0, 60));
      }
    }
    final exp = _baseDelayMs * pow(2, attempt).toInt();
    final capped = min(exp, _maxDelayMs);
    final jitter = Random().nextInt(300);
    return Duration(milliseconds: capped + jitter);
  }
}
