/// A short, user-facing (Thai) message for an error shown in the UI.
///
/// Strips the `Exception: ` prefix, translates known backend/validator errors
/// to Thai, and hides raw technical/Dart dumps (DioException, SocketException,
/// Go-validator strings, …) behind a clean Thai fallback — so users never see
/// `Exception: …`, a stack trace, or a raw English backend error. A clean,
/// already-Thai backend message is passed through as-is.
String friendlyError(
  Object? e, {
  String fallback = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
}) {
  if (e == null) return fallback;
  var s = e.toString().trim();
  const prefix = 'Exception: ';
  if (s.startsWith(prefix)) s = s.substring(prefix.length).trim();
  if (s.isEmpty) return fallback;

  // Translate a recognised backend error (Go validator, common English
  // phrases) to Thai before anything else.
  final mapped = backendErrorToThai(s);
  if (mapped != null) return mapped;

  const technical = [
    'DioException',
    'SocketException',
    'HandshakeException',
    'FormatException',
    'TimeoutException',
    'RangeError',
    'NoSuchMethod',
    'Null check',
    'Failed host lookup',
    "type '",
    'Connection ',
    'errno',
    'Stacktrace',
    // Raw backend shapes we never want to show verbatim.
    'invalid request',
    'validation for',
    'Key:',
    'Error:Field',
  ];
  if (technical.any(s.contains)) return fallback;

  // Anything left is a clean message (often already Thai) — show it.
  return s;
}

/// Maps a known backend error string to a Thai, user-facing message, or null
/// when it isn't one we recognise (so the caller can fall back). Handles Go
/// `validator` errors of the form:
///   "...Key: 'CreateOrderRequest.RecipientPhone' Error:Field validation for
///    'RecipientPhone' failed on the 'phone_th' tag"
/// plus a few common English phrases.
String? backendErrorToThai(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return null;

  final v = RegExp(
    r"validation for '(\w+)' failed on the '(\w+)' tag",
  ).firstMatch(s);
  if (v != null) {
    final label = _fieldLabelTh(v.group(1)!);
    final tag = v.group(2)!.toLowerCase();
    switch (tag) {
      case 'phone_th':
        return '$labelไม่ถูกต้อง (ต้องเป็นเบอร์มือถือไทย เช่น 08XXXXXXXX)';
      case 'required':
        return 'กรุณากรอก$label';
      case 'email':
        return 'อีเมลไม่ถูกต้อง';
      case 'min':
      case 'max':
      case 'len':
      case 'gt':
      case 'gte':
      case 'lt':
      case 'lte':
        return '$labelไม่ถูกต้อง';
      default:
        return '$labelไม่ถูกต้อง';
    }
  }

  final lower = s.toLowerCase();
  if (lower.contains('recipientphone')) return 'เบอร์โทรผู้รับไม่ถูกต้อง';
  if (lower.contains('phone') &&
      (lower.contains('valid') || lower.contains('invalid'))) {
    return 'เบอร์โทรไม่ถูกต้อง';
  }
  return null;
}

/// Thai label for a backend field name (as it appears in a validator error).
/// Falls back to a generic noun so the message still reads naturally.
String _fieldLabelTh(String field) {
  switch (field.toLowerCase()) {
    case 'recipientphone':
      return 'เบอร์โทรผู้รับ';
    case 'recipientname':
      return 'ชื่อผู้รับ';
    case 'senderphone':
      return 'เบอร์โทรผู้ส่ง';
    case 'sendername':
      return 'ชื่อผู้ส่ง';
    case 'phone':
      return 'เบอร์โทร';
    case 'pickupaddress':
      return 'จุดรับ';
    case 'dropoffaddress':
    case 'deliveryaddress':
      return 'จุดส่ง';
    case 'packageweightkg':
    case 'weight':
      return 'น้ำหนักพัสดุ';
    case 'codamount':
      return 'ยอดเก็บเงินปลายทาง';
    case 'paymentmethod':
      return 'วิธีชำระเงิน';
    default:
      return 'ข้อมูล';
  }
}
