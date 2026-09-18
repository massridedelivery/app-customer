import 'package:customer_app/features/payment/domain/models/payment_intent.dart';

abstract interface class IPaymentRepository {
  Future<void> saveCard({required String cardToken, required String email});

  /// Creates a PromptPay payment intent for a ride [jobId] (SCRUM-35 §2.1).
  /// No `amount` is sent — the backend derives it from the job fare.
  /// [cardToken] is optional and only sent for card payments (a provider card
  /// token, e.g. Beam); omitted for PROMPTPAY/CASH.
  Future<PaymentIntent> createIntent({
    required String jobId,
    required String paymentMethod,
    String? cardToken,
  });

  /// Creates a PromptPay payment intent for a messenger/food [orderId]
  /// (SCRUM-35 §3.2/§3.3 target contract). Amount is server-derived from the
  /// order total. NOTE: rejected by the backend until phase-1 order-total
  /// lookup ships — callers must surface the error gracefully.
  Future<PaymentIntent> createIntentForOrder({
    required String orderId,
    required String paymentMethod,
    String? cardToken,
  });

  /// Polls a single intent by its id (SCRUM-35 §2.2).
  Future<PaymentIntent> getIntent(String intentId);

  /// Convenience lookup of the intent owning a job — used for idempotency
  /// before creating a new intent. Returns null if none exists.
  Future<PaymentIntent?> getIntentByJob(String jobId);

  /// Same idempotency lookup keyed by order (SCRUM-35 §2.2).
  Future<PaymentIntent?> getIntentByOrder(String orderId);
}
