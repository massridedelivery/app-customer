import 'package:flutter/widgets.dart';

/// Date / time display for the app's current language — the one place dates
/// are turned into text.
///
/// Thai: Thai month names and the Buddhist-era year (`30 ต.ค. 2569`), times
/// as `14:30 น.`. English: `30 Oct 2026`, `14:30`.
///
/// Month names are spelled out here rather than taken from intl so the output
/// doesn't depend on date-symbol initialisation (and is identical in tests).
class AppDates {
  const AppDates(this.languageCode);

  /// Uses the locale the app is currently rendered in (the language picked in
  /// Profile → เปลี่ยนภาษา).
  factory AppDates.of(BuildContext context) =>
      AppDates(Localizations.localeOf(context).languageCode);

  final String languageCode;

  bool get _th => languageCode == 'th';

  static const _monthsShortTh = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
  static const _monthsLongTh = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', //
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const _monthsShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsLongEn = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  int _year(DateTime d) => _th ? d.year + 543 : d.year;

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `30 ต.ค. 2569` / `30 Oct 2026`
  String date(DateTime d) =>
      '${d.day} ${(_th ? _monthsShortTh : _monthsShortEn)[d.month - 1]} ${_year(d)}';

  /// `30 ตุลาคม 2569` / `30 October 2026`
  String dateLong(DateTime d) =>
      '${d.day} ${(_th ? _monthsLongTh : _monthsLongEn)[d.month - 1]} ${_year(d)}';

  /// `14:30` — bare 24h clock for use inside a sentence.
  String clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// `14:30 น.` / `14:30`
  String time(DateTime d) => _th ? '${clock(d)} น.' : clock(d);

  /// `30 ต.ค. 2569, 14:30 น.` / `30 Oct 2026, 14:30`
  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  // ── ISO-8601 strings from the API (converted to device-local time) ────────

  /// [dateTime] of an API timestamp; [fallback] when null/empty, the raw
  /// string when it can't be parsed.
  String isoDateTime(String? iso, {String fallback = '-'}) =>
      _iso(iso, fallback, dateTime);

  /// [date] of an API timestamp (same fallbacks as [isoDateTime]).
  String isoDate(String? iso, {String fallback = '-'}) =>
      _iso(iso, fallback, date);

  /// [time] of an API timestamp (same fallbacks as [isoDateTime]).
  String isoTime(String? iso, {String fallback = '-'}) =>
      _iso(iso, fallback, time);

  String _iso(String? iso, String fallback, String Function(DateTime) f) {
    if (iso == null || iso.isEmpty) return fallback;
    final d = DateTime.tryParse(iso);
    return d == null ? iso : f(d.toLocal());
  }

  /// [utc] shown in Thailand time (UTC+7) whatever the device timezone — for
  /// promo windows, which the backend defines in Bangkok time.
  static DateTime bangkok(DateTime utc) =>
      utc.toUtc().add(const Duration(hours: 7));
}
