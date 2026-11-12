import 'package:customer_app/core/error/food_delivery_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _err(int status, Object? body) {
  final req = RequestOptions(path: '/api/food/orders/1/cancel');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('mapDioErrorToException (backend v1.6.26 food refusals)', () {
    test('409 cancel after accept is a Thai conflict, not a server error', () {
      final e = mapDioErrorToException(
        _err(409, {
          'message': 'cannot cancel order after restaurant has accepted',
        }),
        'Failed to cancel order',
      );
      expect(e, isA<OrderConflictException>());
      expect(e.statusCode, 409);
      expect(e.toString(), 'ร้านอาหารรับคำสั่งซื้อแล้ว จึงยกเลิกไม่ได้');
    });

    test('409 review before delivery / already reviewed', () {
      final notYet = mapDioErrorToException(
        _err(409, {'message': 'cannot review order: status is PREPARING'}),
        'Failed to submit review',
      );
      expect(notYet, isA<OrderConflictException>());
      expect(notYet.toString(), 'รีวิวได้หลังจากได้รับอาหารแล้วเท่านั้น');

      final twice = mapDioErrorToException(
        _err(409, {'message': 'order has already been reviewed'}),
        'Failed to submit review',
      );
      expect(twice.toString(), 'คุณรีวิวคำสั่งซื้อนี้ไปแล้ว');
    });

    test('400 item not in order', () {
      final e = mapDioErrorToException(
        _err(400, {'message': 'item not found in order: abc'}),
        'Failed to submit review',
      );
      expect(e.statusCode, 400);
      expect(
        e.toString(),
        'มีเมนูที่ไม่อยู่ในคำสั่งซื้อนี้ กรุณาลองใหม่อีกครั้ง',
      );
    });

    test('other text passes through unchanged', () {
      expect(
        foodOrderErrorText('restaurant is not open'),
        'restaurant is not open',
      );
      final e = mapDioErrorToException(
        _err(409, {'message': 'something else'}),
        'x',
      );
      expect(e.toString(), 'something else');
    });
  });
}
