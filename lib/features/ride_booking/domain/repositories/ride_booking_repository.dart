import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';

abstract class RideBookingRepository {
  Future<FareEstimationResponse> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  });

  /// Validates a promo against [subtotal] and returns the total discount
  /// amount. Throws if the code is invalid / not applicable.
  Future<double> validatePromo(String code, double subtotal);

  Future<List<RidePromo>> getDiscoverPromos();

  Future<String> createJob({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    String? vehicleTypeId,
    String? promoCode,
  });
}
