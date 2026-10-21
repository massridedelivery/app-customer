import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/error/food_delivery_exception.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(dynamic data, {int status = 422}) {
  final req = RequestOptions(path: '/api/customer/jobs/estimate');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  group('apiErrorMessage', () {
    test('prefers the server-provided message on a bad response', () {
      final err = _badResponse({'message': 'dropoff is outside service area'});
      expect(apiErrorMessage(err), 'dropoff is outside service area');
    });

    test('reads Laravel-style validation errors (first field, first msg)', () {
      final err = _badResponse({
        'errors': {
          'dropoff_lat': ['The dropoff lat field is required.'],
        },
      });
      expect(apiErrorMessage(err), 'The dropoff lat field is required.');
    });

    test('falls back to a status-based message when body has no message', () {
      final err = _badResponse({'foo': 'bar'}, status: 422);
      expect(apiErrorMessage(err), 'ข้อมูลคำขอไม่ถูกต้อง กรุณาตรวจสอบแล้วลองใหม่');
    });

    test('maps 5xx to a server-down message', () {
      final err = _badResponse(null, status: 500);
      expect(apiErrorMessage(err), 'ระบบขัดข้องชั่วคราว กรุณาลองใหม่ภายหลัง');
    });

    test('maps connection errors to a network message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(
        apiErrorMessage(err),
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
      );
    });

    test('strips the "Exception: " prefix from a plain Exception', () {
      expect(
        apiErrorMessage(Exception('ไม่สามารถคำนวณค่าโดยสารได้ กรุณาลองใหม่')),
        'ไม่สามารถคำนวณค่าโดยสารได้ กรุณาลองใหม่',
      );
    });

    test('uses the supplied fallback for unmapped/empty errors', () {
      expect(
        apiErrorMessage(null, fallback: 'x'),
        'x',
      );
    });

    test('never leaks the raw DioException validateStatus dump', () {
      // The bug this replaces: the whole DioException.toString() reaching the UI.
      final err = _badResponse({'message': 'bad'}, status: 422);
      final msg = apiErrorMessage(err);
      expect(msg.contains('DioException'), isFalse);
      expect(msg.contains('validateStatus'), isFalse);
    });

    test('our own messages follow the language; server text is kept', () {
      expect(
        apiErrorMessage(_badResponse(null, status: 500), languageCode: 'en'),
        'The system is temporarily unavailable. Please try again later.',
      );
      expect(
        apiErrorMessage(null, languageCode: 'en'),
        'Something went wrong. Please try again.',
      );
      expect(
        apiErrorMessage(
          _badResponse({'message': 'dropoff is outside service area'}),
          languageCode: 'en',
        ),
        'dropoff is outside service area',
      );
    });
  });

  group('service area (422 out of zone)', () {
    final outOfZone = _badResponse({
      'error': 'service not available in your area',
    });

    test('maps to the localized notice, not the raw English', () {
      expect(
        apiErrorMessage(outOfZone, languageCode: 'th'),
        'ยังไม่เปิดให้บริการในพื้นที่นี้',
      );
      expect(
        apiErrorMessage(outOfZone, languageCode: 'en'),
        "Service isn't available in this area yet",
      );
    });

    test('is recognised raw, mapped, or wrapped in an Exception', () {
      expect(isServiceAreaError(outOfZone), isTrue);
      expect(
        isServiceAreaError(Exception('ยังไม่เปิดให้บริการในพื้นที่นี้')),
        isTrue,
      );
      expect(isServiceAreaError(_badResponse({'error': 'bad promo'})), isFalse);
      expect(isServiceAreaError(null), isFalse);
    });

    test('friendlyError and the food mapper use the same notice', () {
      expect(
        friendlyError('service not available in your area', languageCode: 'th'),
        'ยังไม่เปิดให้บริการในพื้นที่นี้',
      );
      final mapped = mapDioErrorToException(outOfZone, 'fallback');
      expect(mapped, isA<CoverageException>());
      expect(isServiceAreaMessage(mapped.message), isTrue);
    });
  });
}
