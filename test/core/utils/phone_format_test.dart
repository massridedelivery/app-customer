import 'package:customer_app/core/utils/phone_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Thai input → E.164', () {
    expect(toE164Thai('0812345678'), '+66812345678');
    expect(toE164Thai('812345678'), '+66812345678');
    expect(toE164Thai('+66812345678'), '+66812345678');
    expect(toE164Thai('66812345678'), '+66812345678');
    expect(toE164Thai('081-234 5678'), '+66812345678');
  });

  test('valid Thai E.164', () {
    expect(isThaiE164('+66812345678'), isTrue);
    expect(isThaiE164('+6621234567'), isTrue); // Bangkok landline
    expect(isThaiE164('+668123'), isFalse);
    expect(isThaiE164('0812345678'), isFalse);
  });

  test('display', () {
    expect(displayThaiPhone('+66812345678'), '081 234 5678');
    expect(displayThaiPhone('+6621234567'), '021234567');
    expect(displayThaiPhone('+15551234'), '+15551234');
  });
}
