import 'package:customer_app/features/ride_booking/domain/models/ride_quote.dart';
abstract class DispatchRideUseCase {
  Future<RideBooking> call({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
    bool? usePoints,
    int? pointsToUse,
  });
}
