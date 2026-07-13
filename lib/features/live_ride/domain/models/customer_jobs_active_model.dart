import 'package:freezed_annotation/freezed_annotation.dart';

// จำเป็นต้องมี 2 บรรทัดนี้เสมอเพื่อให้ build_runner ทำงานได้
part 'customer_jobs_active_model.freezed.dart';
part 'customer_jobs_active_model.g.dart';

@freezed
abstract class CustomerJobsActiveModel with _$CustomerJobsActiveModel {
  const factory CustomerJobsActiveModel({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'customer_id') @Default('') String customerId,
    @JsonKey(name: 'driver_id') @Default('') String driverId,
    @JsonKey(name: 'vehicle_type_id') @Default('') String vehicleTypeId,
    @JsonKey(name: 'pickup_lat') @Default(0.0) double pickupLat,
    @JsonKey(name: 'pickup_lng') @Default(0.0) double pickupLng,
    @JsonKey(name: 'dropoff_lat') @Default(0.0) double dropoffLat,
    @JsonKey(name: 'dropoff_lng') @Default(0.0) double dropoffLng,
    @JsonKey(name: 'pickup_address') @Default('') String pickupAddress,
    @JsonKey(name: 'dropoff_address') @Default('') String dropoffAddress,
    @JsonKey(name: 'status') @Default('') String status,
    @JsonKey(name: 'fare') @Default(0.0) double fare,
    @JsonKey(name: 'distance_km') @Default(0.0) double distanceKm,
    @JsonKey(name: 'is_multi_stop') @Default(false) bool isMultiStop,
    @JsonKey(name: 'is_scheduled') @Default(false) bool isScheduled,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,
    @JsonKey(name: 'payment_method') @Default('') String paymentMethod,
    @JsonKey(name: 'discount') @Default(0.0) double discount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'driver_info') DriverJobInfoModel? driverJobInfo,
    @JsonKey(name: 'customer_info') CustomerJobInfoModel? customerJobInfo,
    @JsonKey(name: 'polyline') @Default('') String polyline,
    @JsonKey(name: 'is_intercity') @Default(false) bool isIntercity,
    @JsonKey(name: 'back_to_back_notified')
    @Default(false)
    bool backToBackNotified,
    @JsonKey(name: 'booking_type') @Default('') String bookingType,
    @JsonKey(name: 'avoid_tolls') @Default(false) bool avoidTolls,
    @JsonKey(name: 'toll_fee') @Default(0.0) double tollFee,
    @JsonKey(name: 'toll_paid_by') @Default('') String tollPaidBy,
    @JsonKey(name: 'waiting_time_pickup_min')
    @Default(0)
    int waitingTimePickupMin,
    @JsonKey(name: 'waiting_time_stops_min')
    @Default(0)
    int waitingTimeStopsMin,
    @JsonKey(name: 'waiting_fee') @Default(0.0) double waitingFee,
  }) = _CustomerJobsActiveModel;

  factory CustomerJobsActiveModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerJobsActiveModelFromJson(json);
}

@freezed
abstract class DriverJobInfoModel with _$DriverJobInfoModel {
  const factory DriverJobInfoModel({
    @JsonKey(name: 'full_name') @Default('') String fullName,
    @JsonKey(name: 'phone') @Default('') String phone,
    @JsonKey(name: 'avatar_url') @Default('') String avatarUrl,
    @JsonKey(name: 'rating') @Default(0.0) double rating,
    @JsonKey(name: 'vehicle_plate') @Default('') String vehiclePlate,
    @JsonKey(name: 'vehicle_color') @Default('') String vehicleColor,
    @JsonKey(name: 'vehicle_model') @Default('') String vehicleModel,
    @JsonKey(name: 'vehicle_year') @Default(0) int vehicleYear,
    @JsonKey(name: 'vehicle_province') @Default('') String vehicleProvince,
    @JsonKey(name: 'vehicle_type_name') @Default('') String vehicleTypeName,
    @JsonKey(name: 'vehicle_type_display_name')
    @Default('')
    String vehicleTypeDisplayName,
  }) = _DriverJobInfoModel;

  factory DriverJobInfoModel.fromJson(Map<String, dynamic> json) =>
      _$DriverJobInfoModelFromJson(json);
}

@freezed
abstract class CustomerJobInfoModel with _$CustomerJobInfoModel {
  const factory CustomerJobInfoModel({
    @JsonKey(name: 'full_name') @Default('') String fullName,
    @JsonKey(name: 'phone') @Default('') String phone,
  }) = _CustomerJobInfoModel;

  factory CustomerJobInfoModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerJobInfoModelFromJson(json);
}
