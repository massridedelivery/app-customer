import 'package:customer_app/features/ride_booking/domain/models/fare_estimation_response.dart';

abstract class EstimateFareUseCase {
  Future<FareEstimationResponse> call({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? promoCode,
    String? vehicleTypeId,
  });
}
