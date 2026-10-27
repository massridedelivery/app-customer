import 'package:customer_app/features/live_ride/domain/models/customer_jobs_active_model.dart';
import 'package:customer_app/core/utils/ride_payable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_profile_model.freezed.dart';
part 'driver_profile_model.g.dart';

@freezed
abstract class DriverProfileModel with _$DriverProfileModel {
  const factory DriverProfileModel({
    required String id,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'driver_id') required String driverId,
    @JsonKey(name: 'vehicle_type_id') required String vehicleTypeId,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'pickup_address') required String pickupAddress,
    @JsonKey(name: 'dropoff_address') required String dropoffAddress,
    required String status,
    required double fare,
    @JsonKey(name: 'distance_km') required double distanceKm,
    @JsonKey(name: 'is_multi_stop') required bool isMultiStop,
    @JsonKey(name: 'total_distance_km') required double totalDistanceKm,
    @JsonKey(name: 'total_duration_min') required double totalDurationMin,
    @JsonKey(name: 'scheduled_at') String? scheduledAt,
    @JsonKey(name: 'is_scheduled') required bool isScheduled,
    @JsonKey(name: 'dispatcher_notified_at')
    required DateTime dispatcherNotifiedAt,
    @JsonKey(name: 'accepted_at') required DateTime acceptedAt,
    @JsonKey(name: 'arrived_at_pickup_at') required DateTime arrivedAtPickupAt,
    @JsonKey(name: 'picked_up_at') required DateTime pickedUpAt,
    @JsonKey(name: 'completed_at') required DateTime completedAt,
    @JsonKey(name: 'cancelled_at') String? cancelledAt,
    @JsonKey(name: 'cancelled_by') String? cancelledBy,
    @JsonKey(name: 'cancel_reason') String? cancelReason,
    @JsonKey(name: 'cancellation_fee') required double cancellationFee,
    @JsonKey(name: 'driver_compensation') required double driverCompensation,
    @JsonKey(name: 'rating_by_customer') required int ratingByCustomer,
    @JsonKey(name: 'customer_comment') required String customerComment,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'promo_id') String? promoId,
    required double discount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'trace_id') required String traceId,
    required String polyline,
    @JsonKey(name: 'driver_info') required DriverInfoModel driverInfo,
    @JsonKey(name: 'customer_info') required CustomerInfoModel customerInfo,
    required List<StopModel> stops,
    @JsonKey(name: 'navigation_urls')
    required NavigationUrlsModel navigationUrls,
    @JsonKey(name: 'avoid_tolls') required bool avoidTolls,
    @JsonKey(name: 'toll_fee') required double tollFee,
    @JsonKey(name: 'toll_paid_by') required String tollPaidBy,
    @JsonKey(name: 'waiting_time_pickup_min') required int waitingTimePickupMin,
    @JsonKey(name: 'waiting_time_stops_min') required int waitingTimeStopsMin,
    @JsonKey(name: 'waiting_fee') required double waitingFee,
    @JsonKey(name: 'is_intercity') required bool isIntercity,
    @JsonKey(name: 'distance_category') required String distanceCategory,
    @JsonKey(name: 'booking_type') required String bookingType,
    // dev102: the backend's total due (0 once paid) — see rideAmountDue.
    @JsonKey(name: 'amount_due') double? amountDue,
    @JsonKey(name: 'points_used') @Default(0) int pointsUsed,
    @JsonKey(name: 'points_discount') @Default(0.0) double pointsDiscount,
    @JsonKey(name: 'payment_status') @Default('') String paymentStatus,
    // Unpaid cancellation fees from earlier rides this ride carries.
    @JsonKey(name: 'prior_cancel_fee') @Default(0.0) double priorCancelFee,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromActiveJob(CustomerJobsActiveModel job) {
    return DriverProfileModel(
      id: job.id,
      customerId: job.customerId,
      driverId: job.driverId,
      vehicleTypeId: job.vehicleTypeId,
      pickupLat: job.pickupLat,
      pickupLng: job.pickupLng,
      dropoffLat: job.dropoffLat,
      dropoffLng: job.dropoffLng,
      pickupAddress: job.pickupAddress,
      dropoffAddress: job.dropoffAddress,
      status: job.status,
      fare: job.fare,
      distanceKm: job.distanceKm,
      isMultiStop: job.isMultiStop,
      totalDistanceKm: job.distanceKm,
      totalDurationMin: 0.0,
      isScheduled: job.isScheduled,
      dispatcherNotifiedAt: job.acceptedAt ?? DateTime.now(),
      acceptedAt: job.acceptedAt ?? DateTime.now(),
      arrivedAtPickupAt: DateTime.now(),
      pickedUpAt: DateTime.now(),
      completedAt: DateTime.now(),
      cancellationFee: 0.0,
      driverCompensation: 0.0,
      ratingByCustomer: 0,
      customerComment: '',
      paymentMethod: job.paymentMethod,
      discount: job.discount,
      createdAt: job.createdAt ?? DateTime.now(),
      updatedAt: job.updatedAt ?? DateTime.now(),
      traceId: '',
      polyline: job.polyline,
      driverInfo: DriverInfoModel(
        fullName: job.driverJobInfo?.fullName ?? '',
        phone: job.driverJobInfo?.phone ?? '',
        avatarUrl: job.driverJobInfo?.avatarUrl ?? '',
        rating: job.driverJobInfo?.rating ?? 0.0,
        vehiclePlate: job.driverJobInfo?.vehiclePlate ?? '',
        vehicleColor: job.driverJobInfo?.vehicleColor ?? '',
        vehicleModel: job.driverJobInfo?.vehicleModel ?? '',
        vehicleYear: job.driverJobInfo?.vehicleYear ?? 0,
        vehicleProvince: job.driverJobInfo?.vehicleProvince ?? '',
        vehicleTypeName: job.driverJobInfo?.vehicleTypeName ?? '',
        vehicleTypeDisplayName: job.driverJobInfo?.vehicleTypeDisplayName ?? '',
      ),
      customerInfo: CustomerInfoModel(
        fullName: job.customerJobInfo?.fullName ?? '',
        phone: job.customerJobInfo?.phone ?? '',
        avatarUrl: '',
      ),
      stops: [],
      navigationUrls: const NavigationUrlsModel(
        googleMaps: '',
        waze: '',
        appleMaps: '',
      ),
      avoidTolls: job.avoidTolls,
      tollFee: job.tollFee,
      tollPaidBy: job.tollPaidBy,
      waitingTimePickupMin: job.waitingTimePickupMin,
      waitingTimeStopsMin: job.waitingTimeStopsMin,
      waitingFee: job.waitingFee,
      isIntercity: job.isIntercity,
      distanceCategory: '',
      bookingType: job.bookingType,
      amountDue: job.amountDue,
      pointsUsed: job.pointsUsed,
      pointsDiscount: job.pointsDiscount,
      paymentStatus: job.paymentStatus,
      priorCancelFee: job.priorCancelFee,
    );
  }

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(json);
}

extension DriverProfilePayable on DriverProfileModel {
  /// What the rider pays for this job (backend `amount_due` when it applies).
  double get payable => rideAmountDue(
    amountDue: amountDue,
    paymentStatus: paymentStatus,
    fare: fare,
    discount: discount,
    tollFee: tollFee,
    waitingFee: waitingFee,
    pointsDiscount: pointsDiscount,
    priorCancelFee: priorCancelFee,
  );
}

@freezed
abstract class DriverInfoModel with _$DriverInfoModel {
  const factory DriverInfoModel({
    @JsonKey(name: 'full_name') required String fullName,
    required String phone,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
    required double rating,
    @JsonKey(name: 'vehicle_plate') required String vehiclePlate,
    @JsonKey(name: 'vehicle_color') required String vehicleColor,
    @JsonKey(name: 'vehicle_model') required String vehicleModel,
    @JsonKey(name: 'vehicle_year') required int vehicleYear,
    @JsonKey(name: 'vehicle_province') required String vehicleProvince,
    @JsonKey(name: 'vehicle_type_name') required String vehicleTypeName,
    @JsonKey(name: 'vehicle_type_display_name')
    required String vehicleTypeDisplayName,
  }) = _DriverInfoModel;

  factory DriverInfoModel.fromJson(Map<String, dynamic> json) =>
      _$DriverInfoModelFromJson(json);
}

@freezed
abstract class CustomerInfoModel with _$CustomerInfoModel {
  const factory CustomerInfoModel({
    @JsonKey(name: 'full_name') required String fullName,
    required String phone,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
  }) = _CustomerInfoModel;

  factory CustomerInfoModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerInfoModelFromJson(json);
}

@freezed
abstract class StopModel with _$StopModel {
  const factory StopModel({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    required int sequence,
    @JsonKey(name: 'stop_type') required String stopType,
    required double lat,
    required double lng,
    required String address,
    @JsonKey(name: 'arrival_time') required DateTime arrivalTime,
    @JsonKey(name: 'departure_time') required DateTime departureTime,
    @JsonKey(name: 'waiting_time_min') required int waitingTimeMin,
  }) = _StopModel;

  factory StopModel.fromJson(Map<String, dynamic> json) =>
      _$StopModelFromJson(json);
}

@freezed
abstract class NavigationUrlsModel with _$NavigationUrlsModel {
  const factory NavigationUrlsModel({
    @JsonKey(name: 'google_maps') required String googleMaps,
    required String waze,
    @JsonKey(name: 'apple_maps') required String appleMaps,
  }) = _NavigationUrlsModel;

  factory NavigationUrlsModel.fromJson(Map<String, dynamic> json) =>
      _$NavigationUrlsModelFromJson(json);
}
