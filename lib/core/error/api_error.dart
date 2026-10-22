import 'package:customer_app/core/localization/app_language.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

/// Maps any thrown error (especially a [DioException]) to a short, user-facing
/// message. Keeps raw/technical detail (stack traces, "validateStatus was
/// configured to throw…") out of the UI — that still goes to the debug logs
/// for diagnosis. Prefer the server-provided message when present so the real
/// reason (e.g. which field failed a 422 validation) surfaces instead of a
/// generic string.
///
/// Our own messages follow the app's current language ([languageCode]
/// overrides it); a server-provided message is shown as sent.
String apiErrorMessage(
  Object? error, {
  String? fallback,
  String? languageCode,
}) {
  final l10n = AppLanguage.l10n(languageCode);
  final generic = fallback ?? l10n.errGeneric;
  if (error == null) return generic;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.errTimeout;
      case DioExceptionType.connectionError:
        return l10n.errConnection;
      case DioExceptionType.badResponse:
        // The server's own message is the most useful — it names the reason.
        final serverMsg = _serverMessage(error.response?.data);
        if (serverMsg != null && isServiceAreaMessage(serverMsg)) {
          return l10n.errServiceAreaUnavailable;
        }
        if (serverMsg != null) return serverMsg;
        return _statusMessage(error.response?.statusCode, l10n) ?? generic;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return generic;
    }
  }

  // Plain Exception: strip the "Exception: " prefix Dart prepends so a wrapped
  // friendly message shows cleanly.
  final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  return text.trim().isEmpty ? generic : text.trim();
}

/// The backend's out-of-zone refusal — a 422 `{"error":"service not available
/// in your area"}` from the ride estimate / ride create / food order — or the
/// localized message it was already mapped to.
bool isServiceAreaMessage(String? text) {
  if (text == null) return false;
  if (text.toLowerCase().contains('service not available')) return true;
  return text.contains(AppLanguage.l10n('th').errServiceAreaUnavailable) ||
      text.contains(AppLanguage.l10n('en').errServiceAreaUnavailable);
}

/// Whether [error] (a [DioException], or an exception wrapping its message)
/// is the out-of-zone refusal — screens show it as a notice, not a failure.
bool isServiceAreaError(Object? error) {
  if (error == null) return false;
  if (error is DioException) {
    return isServiceAreaMessage(_serverMessage(error.response?.data));
  }
  return isServiceAreaMessage(error.toString());
}

/// Pulls a human-readable message out of a JSON error body, if present.
/// Handles `{message}`, `{error}`, and Laravel-style `{errors: {field: [..]}}`.
String? _serverMessage(dynamic data) {
  if (data is! Map) return null;

  final msg = data['message'] ?? data['error'];
  if (msg is String && msg.trim().isNotEmpty) return msg.trim();

  final errors = data['errors'];
  if (errors is Map && errors.isNotEmpty) {
    final first = errors.values.first;
    if (first is List && first.isNotEmpty) return first.first.toString();
    if (first is String && first.trim().isNotEmpty) return first.trim();
  }
  return null;
}

String? _statusMessage(int? status, AppLocalizations l10n) {
  if (status == null) return null;
  if (status == 401 || status == 403) return l10n.errUnauthorized;
  if (status == 404) return l10n.errNotFound;
  if (status == 429) return l10n.errTooManyRequests;
  if (status >= 500) return l10n.errServer;
  if (status >= 400) return l10n.errBadRequest;
  return null;
}

/// A backend error in the shared shape
/// `{"code": "POINTS_INSUFFICIENT", "error": "<Thai>", "message": "<Thai>", …extra}`.
///
/// [message] is the server's own `error` (else `message`) text, shown as is —
/// never translated or rewritten; screens branch on [code]. Errors without a
/// body (timeouts, no connection) get the app's own localized message and a
/// null [code], with [isNetwork] set so the caller can offer a retry.
class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.code,
    this.statusCode,
    this.extra = const {},
    this.isNetwork = false,
  });

  final String message;
  final String? code;
  final int? statusCode;

  /// The rest of the error body, e.g. `balance`, `max_usable_points`.
  final Map<String, dynamic> extra;
  final bool isNetwork;

  /// An int field from [extra] (`balance`, `max_usable_points`, …).
  int? intExtra(String key) {
    final v = extra[key];
    return v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  }

  factory ApiError.from(Object? error, {String? fallback}) {
    if (error is ApiError) return error;
    if (error is DioException) {
      final data = error.response?.data;
      final status = error.response?.statusCode;
      if (data is Map) {
        final body = Map<String, dynamic>.from(data);
        final text = [body['error'], body['message']]
            .whereType<String>()
            .map((s) => s.trim())
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');
        if (text.isNotEmpty) {
          return ApiError(
            message: text,
            code: body['code']?.toString(),
            statusCode: status,
            extra: body,
          );
        }
      }
      final network = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => true,
        _ => false,
      };
      return ApiError(
        message: apiErrorMessage(error, fallback: fallback),
        statusCode: status,
        isNetwork: network,
      );
    }
    return ApiError(message: apiErrorMessage(error, fallback: fallback));
  }

  @override
  String toString() => message;
}
