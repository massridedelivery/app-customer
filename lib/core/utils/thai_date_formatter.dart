/// Formats ISO-8601 timestamps into Thai display strings using the Buddhist
/// calendar (year + 543) and abbreviated Thai month names.
///
/// Single source of truth for the date/time format previously duplicated
/// across the trips, receipt, and order screens.
class ThaiDateFormatter {
  const ThaiDateFormatter._();

  static const List<String> _monthsTh = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// e.g. `4 ธ.ค. 2569, 14:30 น.`
  ///
  /// Returns [fallback] when [iso] is null/empty, and the raw [iso] string
  /// when it cannot be parsed.
  static String dateTime(String? iso, {String fallback = '-'}) {
    if (iso == null || iso.isEmpty) return fallback;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final year = dt.year + 543;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_monthsTh[dt.month - 1]} $year, $hh:$mm น.';
    } catch (_) {
      return iso;
    }
  }

  /// e.g. `14:30 น.`
  ///
  /// Returns [fallback] when [iso] is null/empty, and the raw [iso] string
  /// when it cannot be parsed.
  static String time(String? iso, {String fallback = '-'}) {
    if (iso == null || iso.isEmpty) return fallback;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm น.';
    } catch (_) {
      return iso;
    }
  }
}
