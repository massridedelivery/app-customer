import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/presentation/states/messenger_booking_state.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _points({
  int balance = 30,
  int used = 30,
  double discount = 30,
  String? reason,
}) => {
  'enabled': true,
  'balance': balance,
  'baht_per_point': 1,
  'min_redeem': 10,
  'max_usable_points': 30,
  'used_points': used,
  'discount': discount,
  'reason_unavailable': reason,
};

MessengerEstimate _estimate({
  Map<String, dynamic>? points,
  double total = 49,
  double? toPay,
}) => MessengerEstimate.fromJson({
  'total_fare': total,
  'service_levels': [
    {
      'delivery_type': 'INSTANT',
      'base_fare': total,
      'total_fare': total,
      'points': ?points,
      'amount_to_pay': ?toPay,
    },
  ],
});

void main() {
  group('estimate with points', () {
    test('C1: 30 points on a ฿49 fee leaves ฿19', () {
      final s = MessengerBookingState(
        usePoints: true,
        estimate: _estimate(points: _points(), toPay: 19),
      );
      expect(s.pointsQuote!.usedPoints, 30);
      expect(s.spendsPoints, isTrue);
      expect(s.displayTotalFare, 19);
      expect(s.nothingToPay, isFalse);
    });

    test('C2: a guest gets GUEST, nothing is spent', () {
      final s = MessengerBookingState(
        usePoints: true,
        estimate: _estimate(
          points: _points(balance: 0, used: 0, discount: 0, reason: 'GUEST'),
          toPay: 49,
        ),
      );
      expect(s.pointsQuote!.reasonUnavailable, 'GUEST');
      expect(s.pointsQuote!.usable, isFalse);
      expect(s.spendsPoints, isFalse);
      expect(s.displayTotalFare, 49);
    });

    test('switch off: the quote is shown but not spent', () {
      final s = MessengerBookingState(
        estimate: _estimate(points: _points(used: 0, discount: 0), toPay: 49),
      );
      expect(s.spendsPoints, isFalse);
      expect(s.displayTotalFare, 49);
    });

    test('C6: points covering the whole fee mean nothing to pay', () {
      final s = MessengerBookingState(
        usePoints: true,
        estimate: _estimate(
          total: 25,
          points: _points(used: 25, discount: 25),
          toPay: 0,
        ),
      );
      expect(s.displayTotalFare, 0);
      expect(s.nothingToPay, isTrue, reason: 'placed as cash, no QR');
    });

    test('older backend without points: fare as before', () {
      final s = MessengerBookingState(estimate: _estimate(total: 49));
      expect(s.pointsQuote, isNull);
      expect(s.displayTotalFare, 49);
    });
  });

  group('order with points', () {
    test('C3: 20 points off a ฿49 fee: ฿29 to collect', () {
      final o = MessengerOrder.fromJson({
        'id': 'm1',
        'fare': 49,
        'points_used': 20,
        'points_discount': 20,
        'total_amount': 29,
        'amount_due': 29,
      });
      expect(o.pointsUsed, 20);
      expect(o.listPrice, 29);
      expect(o.amountDue, 29);
    });

    test('older payload without amounts still nets the points', () {
      final o = MessengerOrder.fromJson({
        'id': 'm1',
        'fare': 49,
        'points_used': 20,
        'points_discount': 20,
      });
      expect(o.deliveryFee, 29);
      expect(o.listPrice, 29);
    });
  });
}
