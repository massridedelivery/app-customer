import 'package:customer_app/core/utils/phone_format.dart';
import 'package:dio/dio.dart';
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

  test('valid Thai mobile as typed', () {
    for (final ok in [
      '0812345678',
      '081-234-5678',
      '081 234 5678',
      '+66812345678',
      '+66 81 234 5678',
    ]) {
      expect(isValidThaiMobile(ok), isTrue, reason: ok);
    }
    for (final bad in [
      '',
      '081234567', // 9 digits
      '08123456789', // 11 digits
      '812345678', // no leading 0
      '1812345678', // 10 digits, no leading 0
      '+6681234567', // +66 and 8 digits
      '+668123456789', // +66 and 10 digits
      '66812345678',
    ]) {
      expect(isValidThaiMobile(bad), isFalse, reason: bad);
    }
  });

  test('input formatter strips separators and caps the length', () {
    String type(String text) => const ThaiMobileInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
        .text;
    expect(type('081-234-5678'), '0812345678');
    expect(type('081 234 5678'), '0812345678');
    expect(type('08123456789'), '0812345678');
    expect(type('+66 81 234 5678'), '+66812345678');
    expect(type('+6681234567890'), '+66812345678');
    expect(type('08a1'), '081');
  });

  test('INVALID_PHONE carries the server text', () {
    DioException err(int status, Object? data) => DioException(
      requestOptions: RequestOptions(path: '/auth/otp/send'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/otp/send'),
        statusCode: status,
        data: data,
      ),
    );
    expect(
      invalidPhoneMessage(
        err(400, {'code': 'INVALID_PHONE', 'error': 'เบอร์โทรไม่ถูกต้อง'}),
      ),
      'เบอร์โทรไม่ถูกต้อง',
    );
    expect(invalidPhoneMessage(err(400, {'code': 'INVALID_PHONE'})), '');
    expect(invalidPhoneMessage(err(429, {'code': 'OTP_RATE_LIMITED'})), isNull);
    expect(invalidPhoneMessage(err(400, {'code': 'OTHER'})), isNull);
    expect(invalidPhoneMessage(StateError('x')), isNull);
  });

  test('display', () {
    expect(displayThaiPhone('+66812345678'), '081 234 5678');
    expect(displayThaiPhone('+6621234567'), '021234567');
    expect(displayThaiPhone('+15551234'), '+15551234');
  });
}
