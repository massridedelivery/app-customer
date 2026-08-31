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
    // 0 = not reviewed yet, 1–5 = customer's star rating (SCRUM-69). Defaults to
    // 0 for legacy orders, so the review button stays visible.
    @JsonKey(name: 'customer_rating') @Default(0) int customerRating,
    // Present only when the customer left a comment (SCRUM-69).
    @JsonKey(name: 'customer_comment') String? customerComment,
    // Delivery mode + server-computed timing (SCRUM-71). Legacy orders come back
    // as INSTANT with express_surcharge 0; the *_min / deliver_by keys may be
    // absent on old orders.
    @JsonKey(name: 'delivery_type') @Default('INSTANT') String deliveryType,
    @JsonKey(name: 'express_surcharge') @Default(0.0) double expressSurcharge,
    @JsonKey(name: 'pickup_eta_min') int? pickupEtaMin,
    @JsonKey(name: 'deliver_by') String? deliverBy,
    // Who pays the delivery fee (dev14): SENDER (default) pays upfront on the
    // customer app; RECIPIENT pays the driver at delivery (order dispatches
    // unpaid). `collect_at` says where the driver collects (PICKUP | DELIVERY).
    @JsonKey(name: 'payer') @Default('SENDER') String payer,
    @JsonKey(name: 'collect_at') String? collectAt,
    @JsonKey(name: 'payment_status') @Default('') String paymentStatus,
    // Delivery-fee due at collection. Server-authoritative; **excludes**
    // cod_amount (goods value) — they are separate debts, shown on separate
    // lines. Absent on legacy orders → fall back to `fare − discount`.
    @JsonKey(name: 'amount_due') double? amountDueRaw,
    // Live ETA to the next stop (dev14). omitempty: absent (not 0) when no
    // driver yet or the position is stale — always null-check before use.
    @JsonKey(name: 'eta_min') int? etaMin,
    @JsonKey(name: 'arrive_at') String? arriveAt,
    @JsonKey(name: 'distance_remaining_m') int? distanceRemainingM,
    // Road-following route (dev14): same value in both keys. Lets the tracking
    // map draw the route without a Google Directions call.
    @JsonKey(name: 'polyline') String? polyline,
    @JsonKey(name: 'encoded_polyline') String? encodedPolyline,
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

  /// Whether the customer has already reviewed this delivery (SCRUM-69).
  bool get isReviewed => customerRating > 0;

  /// The recipient (not the sender) pays the delivery fee at the door (dev14).
  bool get isRecipientPays => payer.toUpperCase() == 'RECIPIENT';

  /// Delivery fee has been settled.
  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  /// A sender-pays PromptPay order whose fee is still owed. QR is scanned in
  /// person at the driver (the rider presents it) — the customer app never
  /// opens its own QR — so this only drives a "scan the driver's QR" notice on
  /// the tracking screen once the driver reaches pickup; the order flips to PAID
  /// over WS/poll when the driver's collection completes.
  bool get isSenderPromptPayUnpaid =>
      !isRecipientPays &&
      paymentMethod.toUpperCase() == 'PROMPTPAY' &&
      !isPaid;

  /// The driver has reached the sender to collect the parcel (and, for
  /// sender-pays PromptPay, the fee). Includes PICKED_UP so a fast status jump
  /// that skips ARRIVED_AT_PICKUP still prompts; DELIVERED is excluded (a
  /// delivered order routes to the payment summary instead).
  bool get isDriverAtPickup {
    final s = status.toUpperCase();
    return s == 'ARRIVED_AT_PICKUP' || s == 'PICKED_UP';
  }

  /// Delivery fee due at collection. Prefers the server's `amount_due`
  /// (authoritative, excludes cod_amount); falls back to `fare − discount` for
  /// legacy orders that don't send it.
  double get amountDue {
    final raw = amountDueRaw;
    if (raw != null) return raw < 0 ? 0 : raw;
    final due = fare - discount;
    return due < 0 ? 0 : due;
  }

  /// The delivery fee for this parcel (fare − discount), regardless of who pays
  /// or where it's collected. Use this for the "ยอดชำระ/ชำระปลายทาง" total —
  /// unlike [amountDue], it is never 0 for a recipient-pays order (where the
  /// sender's own `amount_due` is 0 but the fee still needs to be shown).
  double get deliveryFee {
    final fee = fare - discount;
    return fee < 0 ? 0 : fee;
  }

  /// When the driver is expected at the next stop, or null when the backend
  /// omitted both keys (no driver / stale position). Prefers the absolute
  /// `arrive_at`; else derives from `eta_min` (now + N minutes).
  DateTime? get etaArriveAt {
    final at = arriveAt;
    if (at != null && at.isNotEmpty) {
      final parsed = DateTime.tryParse(at);
      if (parsed != null) return parsed.toLocal();
    }
    final min = etaMin;
    if (min != null) return DateTime.now().add(Duration(minutes: min));
    return null;
  }

  String get formattedCreatedAt => ThaiDateFormatter.dateTime(createdAt);
}
