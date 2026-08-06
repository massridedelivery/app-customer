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
}
