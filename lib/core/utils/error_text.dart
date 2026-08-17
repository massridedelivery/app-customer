/// A short, user-facing (Thai) message for an error shown in the UI.
///
/// Strips the `Exception: ` prefix and hides raw technical/Dart dumps
/// (DioException, SocketException, type errors, …) behind a clean fallback, so
/// users never see `Exception: …` / stack text. A clean backend message (often
/// already Thai) is passed through as-is.
String friendlyError(
  Object? e, {
  String fallback = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
}) {
  if (e == null) return fallback;
  var s = e.toString().trim();
  const prefix = 'Exception: ';
  if (s.startsWith(prefix)) s = s.substring(prefix.length).trim();

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
  ];
  if (s.isEmpty || technical.any(s.contains)) return fallback;
  return s;
}
