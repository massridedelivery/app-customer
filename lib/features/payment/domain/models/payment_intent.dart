import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_intent.freezed.dart';
part 'payment_intent.g.dart';

/// Lifecycle of a payment intent (see SCRUM-35 §2.2).
enum PaymentIntentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('AWAITING_PAYMENT')
  awaitingPayment,
  @JsonValue('PAID')
  paid,
  @JsonValue('FAILED')
  failed,
  @JsonValue('REFUNDED')
  refunded,
  @JsonValue('EXPIRED')
  expired,
  // The driver switched a QR ride to cash (SCRUM-121): the backend voids the
  // intent so the customer can no longer pay it. Treat as terminal so the QR
  // screen stops polling and closes instead of hanging on a dead QR. CANCELLED
  // is accepted too in case the backend uses that spelling.
  @JsonValue('VOIDED')
  voided,
  @JsonValue('CANCELLED')
  cancelled,
  unknown;

  /// The user is done: no more polling needed.
  bool get isTerminal =>
      this == paid ||
      this == failed ||
      this == expired ||
      this == refunded ||
      this == voided ||
      this == cancelled;

  /// The intent was cancelled/voided before payment (e.g. driver switched the
  /// ride to cash) — distinct from a payment that actively failed.
  bool get isVoided => this == voided || this == cancelled;
}

/// The create response uses `intent_id`; the GET response uses `id`.
/// Accept either so a single model covers both shapes.
Object? _readIntentId(Map json, String key) =>
    json['id'] ?? json['intent_id'];

@freezed
abstract class PaymentIntent with _$PaymentIntent {
  const factory PaymentIntent({
    @JsonKey(name: 'id', readValue: _readIntentId) required String id,
    @JsonKey(name: 'job_id') String? jobId,
    @JsonKey(name: 'order_id') String? orderId,
    double? amount,
    String? currency,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(unknownEnumValue: PaymentIntentStatus.unknown)
    @Default(PaymentIntentStatus.pending)
    PaymentIntentStatus status,
    @JsonKey(name: 'qr_code_url') String? qrCodeUrl,
    // 3DS / redirect-based methods (e.g. card via Beam) return a URL to open in
    // a webview/browser; poll the intent to a terminal state afterwards.
    @JsonKey(name: 'charge_url') String? chargeUrl,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'paid_at') String? paidAt,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _PaymentIntent;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentFromJson(json);
}
