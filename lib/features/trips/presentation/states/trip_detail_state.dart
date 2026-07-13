import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';

part 'trip_detail_state.freezed.dart';

@freezed
abstract class TripDetailState with _$TripDetailState {
  const factory TripDetailState({
    @Default(false) bool isLoading,
    String? error,
    HistoryFoodDetails? foodDetails,
    HistoryRideDetails? rideDetails,
  }) = _TripDetailState;
}
