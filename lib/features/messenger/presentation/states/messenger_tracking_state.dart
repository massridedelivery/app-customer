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
  }) = _MessengerTrackingState;
}
