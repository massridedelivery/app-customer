import 'package:customer_app/core/utils/address_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drops a house number the street already opens with', () {
    // Straight off the emulator: the picker showed
    // "229/1, 229/1 Soi Chaeng Watthana 10, Khet Lak Si".
    expect(
      formatAddressParts([
        '229/1',
        '229/1 Soi Chaeng Watthana 10',
        'Khet Lak Si',
        'Bangkok',
      ]),
      '229/1 Soi Chaeng Watthana 10, Khet Lak Si, Bangkok',
    );
  });

  test('collapses identical parts', () {
    expect(
      formatAddressParts(['14', '14', 'Khet Phra Nakhon', null]),
      '14, Khet Phra Nakhon',
    );
  });

  test('keeps parts that merely share a substring', () {
    // "14" only *appears* inside "Soi 140" — both still carry meaning.
    expect(
      formatAddressParts(['14', 'Soi 140', 'Chatuchak', null]),
      '14, Soi 140, Chatuchak',
    );
  });

  test('skips blanks and the geocoder placeholder', () {
    expect(
      formatAddressParts([null, 'Unnamed Road', '  ', 'Bang Sue']),
      'Bang Sue',
    );
  });

  test('returns empty when nothing is usable, for the caller to handle', () {
    expect(formatAddressParts([null, '', 'Unnamed Road']), isEmpty);
  });

  test('is case-insensitive about redundancy', () {
    expect(
      formatAddressParts(['soi ari', 'Soi Ari 4', 'Phaya Thai']),
      'Soi Ari 4, Phaya Thai',
    );
  });

  group('placeLabel', () {
    test('a landmark name comes first, then its address', () {
      expect(
        placeLabel('สยามพารากอน', '991 ถ. พระรามที่ 1 แขวงปทุมวัน'),
        'สยามพารากอน, 991 ถ. พระรามที่ 1 แขวงปทุมวัน',
      );
    });

    test('no name: the address (number, road)', () {
      expect(placeLabel('', '68/100 ถนนรัตนาธิเบศร์'), '68/100 ถนนรัตนาธิเบศร์');
      expect(placeLabel(null, '68/100 ถนนรัตนาธิเบศร์'), '68/100 ถนนรัตนาธิเบศร์');
    });

    test('no address: the name; a name the address opens with is not repeated', () {
      expect(placeLabel('Home', null), 'Home');
      expect(placeLabel('991', '991 ถ. พระรามที่ 1'), '991 ถ. พระรามที่ 1');
    });
  });
}

