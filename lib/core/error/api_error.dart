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
