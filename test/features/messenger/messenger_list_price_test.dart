import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:flutter_test/flutter_test.dart';

MessengerOrder _order(Map<String, dynamic> json) =>
    MessengerOrder.fromJson({'id': 'm1', ...json});

void main() {
  group('MessengerOrder.listPrice', () {
    test('C1: a delivered cash parcel shows its total, not amount_due 0', () {
      final o = _order({
        'status': 'DELIVERED',
        'fare': 63,
        'amount_due': 0,
        'total_amount': 63,
      });
      expect(o.listPrice, 63);
    });

    test('C2: the promo is off the price', () {
      expect(
        _order({'fare': 63, 'discount': 10, 'total_amount': 53}).listPrice,
        53,
      );
    });

    test('C3: a cancelled parcel keeps its price (struck through)', () {
      final o = _order({
        'status': 'CANCELLED',
        'fare': 65,
        'amount_due': 0,
        'total_amount': 65,
      });
      expect(o.isCancelled, isTrue);
      expect(o.listPrice, 65);
    });

    test('C4: a promo covering everything is ฿0', () {
      expect(
        _order({'fare': 33, 'discount': 50, 'total_amount': 0}).listPrice,
        0,
      );
    });

    test('COD goods value is never added', () {
      expect(
        _order({'fare': 63, 'cod_amount': 500, 'total_amount': 63}).listPrice,
        63,
      );
    });

    test('older backend without total_amount: fare − discount', () {
      final o = _order({
        'status': 'DELIVERED',
        'fare': 63,
        'discount': 10,
        'amount_due': 0,
        'cod_amount': 500,
      });
      expect(o.listPrice, 53);
      expect(_order({'fare': 30, 'discount': 50}).listPrice, 0);
    });
  });
}
