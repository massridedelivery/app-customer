import 'package:customer_app/core/utils/app_dates.dart';
import 'package:flutter_test/flutter_test.dart';

// Local (offset-free) ISO strings so DateTime.parse().toLocal() is a no-op and
// the assertions are timezone-independent.
String _localIso(int y, int mo, int d, int h, int mi) =>
    DateTime(y, mo, d, h, mi).toIso8601String();

void main() {
  const th = AppDates('th');
  const en = AppDates('en');
  final d = DateTime(2026, 10, 30, 14, 5);

  group('Thai: Thai months + Buddhist-era year', () {
    test('date / dateLong', () {
      expect(th.date(d), '30 ต.ค. 2569');
      expect(th.dateLong(d), '30 ตุลาคม 2569');
      expect(th.date(DateTime(2026, 1, 9)), '9 ม.ค. 2569');
      expect(th.dateLong(DateTime(2026, 6, 15)), '15 มิถุนายน 2569');
    });

    test('time / dateTime', () {
      expect(th.time(d), '14:05 น.');
      expect(th.clock(d), '14:05');
      expect(th.dateTime(d), '30 ต.ค. 2569, 14:05 น.');
    });
  });

  group('English: English months + Gregorian year', () {
    test('date / dateLong / time / dateTime', () {
      expect(en.date(d), '30 Oct 2026');
      expect(en.dateLong(d), '30 October 2026');
      expect(en.time(d), '14:05');
      expect(en.dateTime(d), '30 Oct 2026, 14:05');
    });
  });

  group('ISO strings from the API', () {
    test('formats a parseable timestamp', () {
      expect(th.isoDateTime(_localIso(2026, 12, 31, 23, 59)),
          '31 ธ.ค. 2569, 23:59 น.');
      expect(en.isoDate(_localIso(2026, 7, 4, 9, 0)), '4 Jul 2026');
      expect(th.isoTime(_localIso(2026, 7, 4, 9, 0)), '09:00 น.');
    });

    test('fallback for null / empty, raw string when unparseable', () {
      expect(th.isoDateTime(null), '-');
      expect(th.isoDateTime(''), '-');
      expect(en.isoDate(null, fallback: ''), '');
      expect(th.isoDateTime('not-a-date'), 'not-a-date');
    });
  });

  test('bangkok() shows a UTC instant in Thailand time', () {
    // 2026-10-30 16:59:59Z is 23:59:59 in Bangkok, still the 30th.
    final bkk = AppDates.bangkok(DateTime.utc(2026, 10, 30, 16, 59, 59));
    expect(th.date(bkk), '30 ต.ค. 2569');
    expect(th.time(bkk), '23:59 น.');
    // 17:00Z rolls over to the next day in Bangkok.
    expect(en.date(AppDates.bangkok(DateTime.utc(2026, 10, 30, 17))),
        '31 Oct 2026');
  });
}
