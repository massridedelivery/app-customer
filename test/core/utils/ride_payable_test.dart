import 'package:customer_app/core/utils/ride_payable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takes the coupon off the fare', () {
    expect(ridePayable(fare: 120, discount: 50), 70);
  });

  test('adds toll and waiting fees', () {
    expect(ridePayable(fare: 120, discount: 50, tollFee: 25, waitingFee: 10),
        105);
  });

  test('a code bigger than the fare makes it free, never negative', () {
    expect(ridePayable(fare: 40, discount: 50), 0);
  });

  test('no coupon → the fare', () {
    expect(ridePayable(fare: 41), 41);
  });

  group('rideAmountDue (dev102 amount_due)', () {
    test('uses the backend amount_due while unpaid', () {
      // 44 fare, 44 coupon → 0 due, same as the driver sees.
      expect(
        rideAmountDue(
          amountDue: 0,
          paymentStatus: 'PENDING',
          fare: 44,
          discount: 44,
        ),
        0,
      );
      expect(
        rideAmountDue(
          amountDue: 135,
          paymentStatus: '',
          fare: 100,
          tollFee: 25,
          waitingFee: 10,
        ),
        135,
      );
    });

    test('after PAID (amount_due → 0) shows the computed total', () {
      expect(
        rideAmountDue(
          amountDue: 0,
          paymentStatus: 'PAID',
          fare: 100,
          discount: 20,
          tollFee: 25,
        ),
        105,
      );
    });

    test('older backend without amount_due computes it', () {
      expect(
        rideAmountDue(
          amountDue: null,
          paymentStatus: '',
          fare: 40,
          discount: 50,
        ),
        0,
      );
    });
  });
}
