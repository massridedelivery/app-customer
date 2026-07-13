import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_order.freezed.dart';
part 'messenger_order.g.dart';

/// Canonical messenger Order (SCRUM-41 §5).
/// Lifecycle: PENDING → ACCEPTED → ARRIVED_AT_PICKUP → PICKED_UP → DELIVERED,
/// terminal CANCELLED. Note: messenger uses `ARRIVED_AT_PICKUP` (no middle
/// underscore) — unlike ride's `ARRIVED_AT_PICK_UP`.
@freezed
abstract class MessengerOrder with _$MessengerOrder {
  const MessengerOrder._();

  const factory MessengerOrder({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'customer_id') @Default('') String customerId,
    @JsonKey(name: 'driver_id') @Default('') String driverId,
    @JsonKey(name: 'vehicle_type_id') @Default('') String vehicleTypeId,
    @JsonKey(name: 'status') @Default('') String status,
    @JsonKey(name: 'pickup_lat') @Default(0.0) double pickupLat,
    @JsonKey(name: 'pickup_lng') @Default(0.0) double pickupLng,
    @JsonKey(name: 'pickup_address') @Default('') String pickupAddress,
    @JsonKey(name: 'dropoff_lat') @Default(0.0) double dropoffLat,
    @JsonKey(name: 'dropoff_lng') @Default(0.0) double dropoffLng,
    @JsonKey(name: 'dropoff_address') @Default('') String dropoffAddress,
    @JsonKey(name: 'recipient_name') @Default('') String recipientName,
    @JsonKey(name: 'recipient_phone') @Default('') String recipientPhone,
    @JsonKey(name: 'package_size_tier') @Default('') String packageSizeTier,
    @JsonKey(name: 'package_weight_kg') @Default(0.0) double packageWeightKg,
    @JsonKey(name: 'package_length_cm') double? packageLengthCm,
    @JsonKey(name: 'package_width_cm') double? packageWidthCm,
    @JsonKey(name: 'package_height_cm') double? packageHeightCm,
    @JsonKey(name: 'notes') @Default('') String notes,
    @JsonKey(name: 'cod_amount') @Default(0.0) double codAmount,
    @JsonKey(name: 'payment_method') @Default('') String paymentMethod,
    @JsonKey(name: 'distance_km') @Default(0.0) double distanceKm,
    @JsonKey(name: 'fare') @Default(0.0) double fare,
    @JsonKey(name: 'discount') @Default(0.0) double discount,
    @JsonKey(name: 'platform_commission') @Default(0.0) double platformCommission,
    @JsonKey(name: 'promo_id') @Default('') String promoId,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    @JsonKey(name: 'accepted_at') @Default('') String acceptedAt,
    @JsonKey(name: 'arrived_at_pickup_at') @Default('') String arrivedAtPickupAt,
    @JsonKey(name: 'picked_up_at') @Default('') String pickedUpAt,
    @JsonKey(name: 'delivered_at') @Default('') String deliveredAt,
    @JsonKey(name: 'cancelled_at') @Default('') String cancelledAt,
    @JsonKey(name: 'cancelled_by') @Default('') String cancelledBy,
    @JsonKey(name: 'cancel_reason') @Default('') String cancelReason,
  }) = _MessengerOrder;

  factory MessengerOrder.fromJson(Map<String, dynamic> json) =>
      _$MessengerOrderFromJson(json);

  bool get hasDriver => driverId.isNotEmpty;
  bool get isDelivered => status.toUpperCase() == 'DELIVERED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isTerminal => isDelivered || isCancelled;

  /// Customer may cancel while PENDING or ACCEPTED (spec §1 transitions).
  bool get isCancellable {
    final s = status.toUpperCase();
    return s == 'PENDING' || s == 'ACCEPTED';
  }

  bool get isCod => paymentMethod.toUpperCase() == 'COD';

  /// `fare` is gross; the customer pays fare − discount.
  double get amountDue {
    final due = fare - discount;
    return due < 0 ? 0 : due;
  }

  String get formattedCreatedAt => ThaiDateFormatter.dateTime(createdAt);
}
