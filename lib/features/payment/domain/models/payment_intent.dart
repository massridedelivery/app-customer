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
  unknown;

  /// The user is done: no more polling needed.
  bool get isTerminal =>
      this == paid || this == failed || this == expired || this == refunded;
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
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'paid_at') String? paidAt,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _PaymentIntent;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentFromJson(json);
}
