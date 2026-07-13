import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'driver_id') String? driverId,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'dropoff_address') String? dropoffAddress,
    required String status,
    required double fare,
    @JsonKey(name: 'distance_km') required double distanceKm,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
    @JsonKey(name: 'rating_by_customer') int? ratingByCustomer,
    @JsonKey(name: 'customer_comment') String? customerComment,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'promo_id') String? promoId,
    required double discount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
