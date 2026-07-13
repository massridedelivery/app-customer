import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'promptpay_state.freezed.dart';

@freezed
abstract class PromptPayState with _$PromptPayState {
  const PromptPayState._();

  const factory PromptPayState({
    PaymentIntent? intent,
    @Default(true) bool isCreating,
    String? error,
    @Default(0) int secondsLeft,
  }) = _PromptPayState;

  PaymentIntentStatus get status =>
      intent?.status ?? PaymentIntentStatus.pending;

  bool get isPaid => status == PaymentIntentStatus.paid;
  bool get isTerminal => status.isTerminal;

  /// True once the QR window has elapsed (or the backend reports EXPIRED).
  bool get isExpired =>
      status == PaymentIntentStatus.expired ||
      (intent != null && !status.isTerminal && secondsLeft <= 0);
}
