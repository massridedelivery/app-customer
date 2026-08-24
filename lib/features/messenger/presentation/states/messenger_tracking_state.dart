import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messenger_tracking_state.freezed.dart';

@freezed
abstract class MessengerTrackingState with _$MessengerTrackingState {
  const factory MessengerTrackingState({
    String? orderId,
    @Default(false) bool isLoading,
    @Default(false) bool isCancelling,
    MessengerOrder? order,
    String? error,
    // Pay-after-match (dev): a sender-pays PromptPay order dispatches unpaid and
    // is charged once the driver reaches pickup. Latched true when that moment
    // arrives so the screen routes to the QR once; cleared on PAID.
    @Default(false) bool awaitingPromptPay,
  }) = _MessengerTrackingState;
}
