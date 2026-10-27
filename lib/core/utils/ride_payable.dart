/// What the rider pays for a ride job: the backend's `fare` is the price
/// before the coupon, so payable = fare - discount + toll + waiting fee,
/// floored at zero (a ฿50 code on a ฿40 fare is ฿0), plus any unpaid
/// cancellation fee carried from an earlier ride (`prior_cancel_fee`, never
/// discounted — the backend's Payable() = RidePayable() + PriorCancelFee).
double ridePayable({
  required double fare,
  double discount = 0,
  double tollFee = 0,
  double waitingFee = 0,
  double pointsDiscount = 0,
  double priorCancelFee = 0,
}) {
  final ride = fare - discount - pointsDiscount + tollFee + waitingFee;
  return (ride < 0 ? 0 : ride) + priorCancelFee;
}

/// The total the rider pays, preferring the backend's `amount_due` (dev102:
/// fare + toll + waiting − discount + carried cancellation fee, the same
/// figure the driver sees) over computing it here. `amount_due` drops to 0
/// once the job is PAID, so after payment fall back to the computed total for
/// the summary.
double rideAmountDue({
  required double? amountDue,
  required String paymentStatus,
  required double fare,
  double discount = 0,
  double tollFee = 0,
  double waitingFee = 0,
  double pointsDiscount = 0,
  double priorCancelFee = 0,
}) {
  if (amountDue != null && paymentStatus.toUpperCase() != 'PAID') {
    return amountDue < 0 ? 0 : amountDue;
  }
  return ridePayable(
    fare: fare,
    discount: discount,
    tollFee: tollFee,
    waitingFee: waitingFee,
    pointsDiscount: pointsDiscount,
    priorCancelFee: priorCancelFee,
  );
}
