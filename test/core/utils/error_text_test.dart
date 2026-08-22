import 'package:customer_app/core/utils/error_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendlyError · backend → Thai', () {
    test('Go validator phone_th error → Thai phone message (not raw English)', () {
      // The exact shape the backend returned on iOS.
      final raw =
          "invalid request: Key: 'CreateOrderRequest.RecipientPhone' "
          "Error:Field validation for 'RecipientPhone' failed on the "
          "'phone_th' tag";
      final out = friendlyError(Exception(raw));
      expect(out, contains('เบอร์โทรผู้รับ'));
      expect(out, contains('ไม่ถูกต้อง'));
      // Never leak the raw English/technical string.
      expect(out.toLowerCase(), isNot(contains('validation')));
      expect(out, isNot(contains('phone_th')));
    });

    test('required tag → "กรุณากรอก<field>"', () {
      final raw =
          "Key: 'X.RecipientName' Error:Field validation for 'RecipientName' "
          "failed on the 'required' tag";
      expect(friendlyError(Exception(raw)), 'กรุณากรอกชื่อผู้รับ');
    });

    test('unknown field falls back to a natural Thai noun', () {
      final raw =
          "Field validation for 'SomethingElse' failed on the 'min' tag";
      expect(friendlyError(raw), 'ข้อมูลไม่ถูกต้อง');
    });

    test('technical Dart dump → Thai fallback', () {
      expect(
        friendlyError(Exception('DioException [bad response]: 500')),
        'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
      );
    });

    test('bare "invalid request" with no parseable field → fallback', () {
      expect(
        friendlyError(Exception('invalid request: something'),
            fallback: 'สร้างออเดอร์ไม่สำเร็จ'),
        'สร้างออเดอร์ไม่สำเร็จ',
      );
    });

    test('clean Thai backend message passes through', () {
      expect(
        friendlyError(Exception('ขณะนี้ยังไม่เปิดให้บริการจัดส่ง')),
        'ขณะนี้ยังไม่เปิดให้บริการจัดส่ง',
      );
    });

    test('backendErrorToThai returns null for a non-backend string', () {
      expect(backendErrorToThai('just some text'), isNull);
    });
  });
}
