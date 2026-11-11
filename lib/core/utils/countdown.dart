/// `42` → `00:42`, `754` → `12:34`, `5400` → `1:30:00`.
String formatCountdown(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return h > 0 ? '$h:${two(m)}:${two(s % 60)}' : '${two(m)}:${two(s % 60)}';
}
