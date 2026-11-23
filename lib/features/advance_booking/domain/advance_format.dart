import 'package:customer_app/features/advance_booking/domain/advance_slots.dart';

/// Pickup times for advance booking, always in Bangkok time:
/// `อา. 22 พ.ย.`, `06:30`, `วันนี้`.
class AdvanceFormat {
  const AdvanceFormat(this.languageCode, {this.today = 'วันนี้'});

  final String languageCode;

  /// The word for today in the current language. Any other day is a date,
  /// so "tomorrow" never hides which day it is.
  final String today;

  bool get _th => languageCode == 'th';

  static const _weekdaysTh = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  static const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthsTh = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _weekdayNamesTh = [
    'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์', //
  ];
  static const _weekdayNamesEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
    'Sunday',
  ];
  static const _monthNamesTh = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', //
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const _monthNamesEn = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `อา. 22 พ.ย.` for a Bangkok wall-clock [day].
  String day(DateTime day) {
    final wd = (_th ? _weekdaysTh : _weekdaysEn)[day.weekday - 1];
    final m = (_th ? _monthsTh : _monthsEn)[day.month - 1];
    return '$wd ${day.day} $m';
  }

  /// `วันนี้` or `อา. 22 พ.ย.` for the Bangkok day of [utc].
  String relativeDay(DateTime utc, {required DateTime now}) {
    final d = AdvanceSlots.toBangkok(utc);
    final n = AdvanceSlots.toBangkok(now);
    final diff = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
    if (diff == 0) return today;
    return day(d);
  }

  /// `06:30`, Bangkok.
  String clock(DateTime utc) {
    final d = AdvanceSlots.toBangkok(utc);
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// `อา. 22 พ.ย. 06:30` (or `วันนี้ 06:30`).
  String when(DateTime utc, {required DateTime now}) =>
      '${relativeDay(utc, now: now)} ${clock(utc)}';

  /// `วันนี้ · อา. 22 พ.ย.` or `อา. 22 พ.ย.` — a list's day heading (no time).
  String dayHeading(DateTime utc, {required DateTime now}) {
    final rel = relativeDay(utc, now: now);
    final full = day(AdvanceSlots.toBangkok(utc));
    return rel == full ? full : '$rel · $full';
  }

  /// `พ.ย.` — the short month of the Bangkok day of [utc].
  String monthShort(DateTime utc) =>
      (_th ? _monthsTh : _monthsEn)[AdvanceSlots.toBangkok(utc).month - 1];

  /// `อังคาร` / `Tuesday` — the weekday of the Bangkok day of [utc].
  String weekdayName(DateTime utc) => (_th ? _weekdayNamesTh : _weekdayNamesEn)[
      AdvanceSlots.toBangkok(utc).weekday - 1];

  /// `24` — the Bangkok day of the month of [utc].
  int dayOfMonth(DateTime utc) => AdvanceSlots.toBangkok(utc).day;

  /// `วันอังคารที่ 24 พฤศจิกายน 2569` (Buddhist year) /
  /// `Tuesday 24 November 2026`.
  String fullDate(DateTime utc) {
    final d = AdvanceSlots.toBangkok(utc);
    final wd = weekdayName(utc);
    if (_th) {
      return 'วัน$wdที่ ${d.day} ${_monthNamesTh[d.month - 1]} ${d.year + 543}';
    }
    return '$wd ${d.day} ${_monthNamesEn[d.month - 1]} ${d.year}';
  }

  /// `11:15 น.` / `11:15`.
  String clockLong(DateTime utc) => _th ? '${clock(utc)} น.' : clock(utc);
}
