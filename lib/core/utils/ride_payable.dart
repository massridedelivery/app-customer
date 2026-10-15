/// What the rider pays for a ride job: the backend's `fare` is the price
/// before the coupon, so payable = fare - discount + toll + waiting fee,
/// floored at zero (a ฿50 code on a ฿40 fare is ฿0).
double ridePayable({
  required double fare,
  double discount = 0,
  double tollFee = 0,
  double waitingFee = 0,
}) {
  final total = fare - discount + tollFee + waitingFee;
  return total < 0 ? 0 : total;
}
