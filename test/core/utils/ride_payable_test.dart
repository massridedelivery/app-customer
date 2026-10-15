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
}
