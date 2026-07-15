import 'package:dio/dio.dart';

/// Maps any thrown error (especially a [DioException]) to a short, user-facing
/// message. Keeps raw/technical detail (stack traces, "validateStatus was
/// configured to throw…") out of the UI — that still goes to the debug logs
/// for diagnosis. Prefer the server-provided message when present so the real
/// reason (e.g. which field failed a 422 validation) surfaces instead of a
/// generic string.
String apiErrorMessage(Object? error, {String? fallback}) {
  final generic = fallback ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  if (error == null) return generic;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่';
      case DioExceptionType.connectionError:
        return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';
      case DioExceptionType.badResponse:
        // The server's own message is the most useful — it names the reason.
        final serverMsg = _serverMessage(error.response?.data);
        if (serverMsg != null) return serverMsg;
        return _statusMessage(error.response?.statusCode) ?? generic;
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

String? _statusMessage(int? status) {
  if (status == null) return null;
  if (status == 401 || status == 403) {
    return 'ไม่มีสิทธิ์ใช้งาน กรุณาเข้าสู่ระบบใหม่';
  }
  if (status == 404) return 'ไม่พบข้อมูลที่ต้องการ';
  if (status >= 500) return 'ระบบขัดข้องชั่วคราว กรุณาลองใหม่ภายหลัง';
  if (status >= 400) return 'ข้อมูลคำขอไม่ถูกต้อง กรุณาตรวจสอบแล้วลองใหม่';
  return null;
}
