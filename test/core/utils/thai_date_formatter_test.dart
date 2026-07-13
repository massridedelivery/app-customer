import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

// Local (offset-free) ISO strings so DateTime.parse().toLocal() is a no-op and
// the assertions are timezone-independent.
String _localIso(int y, int mo, int d, int h, int mi) =>
    DateTime(y, mo, d, h, mi).toIso8601String();

void main() {
  group('ThaiDateFormatter.dateTime', () {
    test('formats with Buddhist year, Thai month abbr, and comma separator', () {
      expect(
        ThaiDateFormatter.dateTime(_localIso(2026, 7, 4, 14, 30)),
        '4 ก.ค. 2569, 14:30 น.',
      );
    });

    test('zero-pads hour and minute', () {
      expect(
        ThaiDateFormatter.dateTime(_localIso(2026, 1, 9, 3, 5)),
        '9 ม.ค. 2569, 03:05 น.',
      );
    });

    test('handles the last month (December -> ธ.ค.)', () {
      expect(
        ThaiDateFormatter.dateTime(_localIso(2026, 12, 31, 23, 59)),
        '31 ธ.ค. 2569, 23:59 น.',
      );
    });

    test('uses a comma separator, never the old double-space variant', () {
      final out = ThaiDateFormatter.dateTime(_localIso(2026, 7, 4, 14, 30));
      expect(out, contains(', '));
      expect(out, isNot(contains('  ')));
    });

    test('returns the fallback for null or empty input', () {
      expect(ThaiDateFormatter.dateTime(null), '-');
      expect(ThaiDateFormatter.dateTime(''), '-');
      expect(ThaiDateFormatter.dateTime(null, fallback: 'N/A'), 'N/A');
    });

    test('returns the raw string when it cannot be parsed', () {
      expect(ThaiDateFormatter.dateTime('not-a-date'), 'not-a-date');
    });
  });

  group('ThaiDateFormatter.time', () {
    test('formats time only, zero-padded', () {
      expect(ThaiDateFormatter.time(_localIso(2026, 7, 4, 9, 7)), '09:07 น.');
    });

    test('returns the fallback for null or empty input', () {
      expect(ThaiDateFormatter.time(null), '-');
      expect(ThaiDateFormatter.time(''), '-');
    });

    test('returns the raw string when it cannot be parsed', () {
      expect(ThaiDateFormatter.time('nope'), 'nope');
    });
  });
}
