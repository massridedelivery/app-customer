import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:customer_app/features/trips/domain/models/trip.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';

part 'trips_state.freezed.dart';

@freezed
abstract class TripsState with _$TripsState {
  const factory TripsState({
    @Default([]) List<Trip> trips,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    HistoryResponse? historyResponse,
    @Default([]) List<HistoryOrder> historyOrders,
    @Default(1) int currentPage,
    @Default(true) bool hasMore,
    @Default(false) bool isHistoryLoading,
    String? historyError,
  }) = _TripsState;
}
