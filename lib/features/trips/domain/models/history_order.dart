import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_order.freezed.dart';
part 'history_order.g.dart';

@freezed
abstract class HistoryResponse with _$HistoryResponse {
  const factory HistoryResponse({
    @Default([]) List<HistoryOrder> data,
    @Default(0) int limit,
    @Default(0) int page,
    @Default(0) int total,
  }) = _HistoryResponse;

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$HistoryResponseFromJson(json);
}

@freezed
abstract class HistoryOrder with _$HistoryOrder {
  const HistoryOrder._();

  const factory HistoryOrder({
    required String id,
    @JsonKey(name: 'created_at') required String createdAt,
    required String status,
    @JsonKey(name: 'total_amount') required double totalAmount,
    required String type,
    @JsonKey(name: 'food_details') HistoryFoodDetails? foodDetails,
    @JsonKey(name: 'ride_details') HistoryRideDetails? rideDetails,
  }) = _HistoryOrder;

  factory HistoryOrder.fromJson(Map<String, dynamic> json) =>
      _$HistoryOrderFromJson(json);

  String get formattedCreatedAt => ThaiDateFormatter.dateTime(createdAt);
}

@freezed
abstract class HistoryFoodDetails with _$HistoryFoodDetails {
  const factory HistoryFoodDetails({
    @JsonKey(name: 'batch_id') String? batchId,
    @JsonKey(name: 'batch_sequence') int? batchSequence,
    @JsonKey(name: 'batched_eta_min') int? batchedEtaMin,
    @JsonKey(name: 'batching_enabled') bool? batchingEnabled,
    @JsonKey(name: 'customer_distance_km') double? customerDistanceKm,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'delay_queue_until') String? delayQueueUntil,
    @JsonKey(name: 'delivered_at') String? deliveredAt,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    @JsonKey(name: 'delivery_fee') double? deliveryFee,
    @JsonKey(name: 'delivery_lat') double? deliveryLat,
    @JsonKey(name: 'delivery_lng') double? deliveryLng,
    @JsonKey(name: 'driver_id') String? driverId,
    @JsonKey(name: 'food_total') double? foodTotal,
    @JsonKey(name: 'fulfillment_distance_km') double? fulfillmentDistanceKm,
    required String id,
    @Default([]) List<HistoryFoodItem> items,
    @JsonKey(name: 'oos_items') @Default([]) List<String> oosItems,
    @JsonKey(name: 'original_eta_min') int? originalEtaMin,
    @JsonKey(name: 'original_total_amount') double? originalTotalAmount,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'placed_at') String? placedAt,
    @JsonKey(name: 'platform_commission') double? platformCommission,
    @JsonKey(name: 'prep_time_adjustment_min') int? prepTimeAdjustmentMin,
    @JsonKey(name: 'promo_discount') double? promoDiscount,
    @JsonKey(name: 'promo_min_spend') double? promoMinSpend,
    @JsonKey(name: 'restaurant_id') String? restaurantId,
    required String status,
    String? tier,
    @JsonKey(name: 'total_amount') double? totalAmount,
    @JsonKey(name: 'trace_id') String? traceId,
  }) = _HistoryFoodDetails;

  factory HistoryFoodDetails.fromJson(Map<String, dynamic> json) =>
      _$HistoryFoodDetailsFromJson(json);
}

@freezed
abstract class HistoryFoodItem with _$HistoryFoodItem {
  const factory HistoryFoodItem({
    required String id,
    @JsonKey(name: 'menu_item_id') required String menuItemId,
    required String name,
    @JsonKey(name: 'order_id') required String orderId,
    required int quantity,
    @JsonKey(name: 'selected_modifiers')
    @Default([])
    List<HistoryModifier> selectedModifiers,
    required double subtotal,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'variant_options') String? variantOptions,
  }) = _HistoryFoodItem;

  factory HistoryFoodItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryFoodItemFromJson(json);
}

@freezed
abstract class HistoryModifier with _$HistoryModifier {
  const factory HistoryModifier({
    required String id,
    required String name,
    required double price,
  }) = _HistoryModifier;

  factory HistoryModifier.fromJson(Map<String, dynamic> json) =>
      _$HistoryModifierFromJson(json);
}

@freezed
abstract class HistoryRideDetails with _$HistoryRideDetails {
  const factory HistoryRideDetails({
    @JsonKey(name: 'accepted_at') String? acceptedAt,
    @JsonKey(name: 'arrived_at_pickup_at') String? arrivedAtPickupAt,
    @JsonKey(name: 'actual_duration_min') double? actualDurationMin,
    @JsonKey(name: 'avoid_tolls') bool? avoidTolls,
    @JsonKey(name: 'back_to_back_notified') bool? backToBackNotified,
    @JsonKey(name: 'booking_type') String? bookingType,
    @JsonKey(name: 'cancel_reason') String? cancelReason,
    @JsonKey(name: 'cancellation_fee') double? cancellationFee,
    @JsonKey(name: 'cancelled_at') String? cancelledAt,
    @JsonKey(name: 'cancelled_by') String? cancelledBy,
    @JsonKey(name: 'completed_at') String? completedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'customer_comment') String? customerComment,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'customer_info') HistoryCustomerInfo? customerInfo,
    @JsonKey(name: 'destination_city') String? destinationCity,
    required double discount,
    @JsonKey(name: 'dispatcher_notified_at') String? dispatcherNotifiedAt,
    @JsonKey(name: 'distance_category') String? distanceCategory,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'driver_compensation') double? driverCompensation,
    @JsonKey(name: 'driver_id') String? driverId,
    @JsonKey(name: 'driver_info') HistoryDriverInfo? driverInfo,
    @JsonKey(name: 'dropoff_address') String? dropoffAddress,
    @JsonKey(name: 'dropoff_lat') double? dropoffLat,
    @JsonKey(name: 'dropoff_lng') double? dropoffLng,
    required double fare,
    required String id,
    @JsonKey(name: 'is_intercity') bool? isIntercity,
    @JsonKey(name: 'is_multi_stop') bool? isMultiStop,
    @JsonKey(name: 'is_queued_next') bool? isQueuedNext,
    @JsonKey(name: 'is_scheduled') bool? isScheduled,
    @JsonKey(name: 'navigation_urls') HistoryNavigationUrls? navigationUrls,
    @JsonKey(name: 'origin_city') String? originCity,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'picked_up_at') String? pickedUpAt,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'pickup_lat') double? pickupLat,
    @JsonKey(name: 'pickup_lng') double? pickupLng,
    String? polyline,
    @JsonKey(name: 'promo_id') String? promoId,
    @JsonKey(name: 'queued_for_driver_id') String? queuedForDriverId,
    @JsonKey(name: 'rating_by_customer') double? ratingByCustomer,
    @JsonKey(name: 'scheduled_at') String? scheduledAt,
    required String status,
    @Default([]) List<HistoryRideStop> stops,
    @JsonKey(name: 'subscription_id') String? subscriptionId,
    @JsonKey(name: 'toll_fee') double? tollFee,
    @JsonKey(name: 'toll_paid_by') String? tollPaidBy,
    @JsonKey(name: 'total_distance_km') double? totalDistanceKm,
    @JsonKey(name: 'total_duration_min') double? totalDurationMin,
    @JsonKey(name: 'trace_id') String? traceId,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'vehicle_type_id') String? vehicleTypeId,
    @JsonKey(name: 'waiting_fee') double? waitingFee,
    @JsonKey(name: 'waiting_time_pickup_min') double? waitingTimePickupMin,
    @JsonKey(name: 'waiting_time_stops_min') double? waitingTimeStopsMin,
  }) = _HistoryRideDetails;

  factory HistoryRideDetails.fromJson(Map<String, dynamic> json) =>
      _$HistoryRideDetailsFromJson(json);
}

@freezed
abstract class HistoryCustomerInfo with _$HistoryCustomerInfo {
  const factory HistoryCustomerInfo({
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
  }) = _HistoryCustomerInfo;

  factory HistoryCustomerInfo.fromJson(Map<String, dynamic> json) =>
      _$HistoryCustomerInfoFromJson(json);
}

@freezed
abstract class HistoryDriverInfo with _$HistoryDriverInfo {
  const factory HistoryDriverInfo({
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
    double? rating,
    @JsonKey(name: 'vehicle_color') String? vehicleColor,
    @JsonKey(name: 'vehicle_model') String? vehicleModel,
    @JsonKey(name: 'vehicle_plate') String? vehiclePlate,
    @JsonKey(name: 'vehicle_province') String? vehicleProvince,
    @JsonKey(name: 'vehicle_type_display_name') String? vehicleTypeDisplayName,
    @JsonKey(name: 'vehicle_type_name') String? vehicleTypeName,
    @JsonKey(name: 'vehicle_year') int? vehicleYear,
  }) = _HistoryDriverInfo;

  factory HistoryDriverInfo.fromJson(Map<String, dynamic> json) =>
      _$HistoryDriverInfoFromJson(json);
}

@freezed
abstract class HistoryNavigationUrls with _$HistoryNavigationUrls {
  const factory HistoryNavigationUrls({
    @JsonKey(name: 'apple_maps') String? appleMaps,
    @JsonKey(name: 'google_maps') String? googleMaps,
    String? waze,
  }) = _HistoryNavigationUrls;

  factory HistoryNavigationUrls.fromJson(Map<String, dynamic> json) =>
      _$HistoryNavigationUrlsFromJson(json);
}

@freezed
abstract class HistoryRideStop with _$HistoryRideStop {
  const factory HistoryRideStop({
    String? address,
    @JsonKey(name: 'arrival_time') String? arrivalTime,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'departure_time') String? departureTime,
    String? id,
    @JsonKey(name: 'job_id') String? jobId,
    double? lat,
    double? lng,
    String? name,
    int? sequence,
    @JsonKey(name: 'stop_type') String? stopType,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'waiting_time_min') double? waitingTimeMin,
  }) = _HistoryRideStop;

  factory HistoryRideStop.fromJson(Map<String, dynamic> json) =>
      _$HistoryRideStopFromJson(json);
}

enum HistoryType { ride, food, mart, messenger }

enum HistoryStatus { ongoing, completed, canceled }
