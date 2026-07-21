import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/trips/domain/models/trip.dart';
import 'package:customer_app/features/trips/presentation/states/trips_state.dart';
import 'package:customer_app/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';

part 'trips_controller.g.dart';

// Parsed off the UI isolate via compute() — see the repository for the same
// rationale on the (larger) history payload.
List<Trip> _parseTrips(List<dynamic> data) =>
    data.map((item) => Trip.fromJson(item as Map<String, dynamic>)).toList();

@riverpod
class TripsController extends _$TripsController {
  @override
  TripsState build() {
    Future.microtask(fetchTrips);
    return const TripsState();
  }

  Future<void> fetchTrips() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.dio.get('/api/customer/trips');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        // Offload to a background isolate; fall back to a local parse if the
        // model can't be sent across the isolate boundary.
        List<Trip> trips;
        try {
          trips = await compute(_parseTrips, data);
        } catch (_) {
          trips = _parseTrips(data);
        }
        state = state.copyWith(trips: trips, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch trips: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred while fetching trips: $e',
      );
    }
  }

  Future<void> fetchHistoryOrders({
    HistoryType? type,
    HistoryStatus? status,
    bool isRefresh = true,
    int limit = 20,
  }) async {
    if (!isRefresh && (!state.hasMore || state.isLoadingMore)) {
      return;
    }

    if (isRefresh) {
      state = state.copyWith(
        isHistoryLoading: true,
        historyError: null,
        historyOrders: [],
        currentPage: 1,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, historyError: null);
    }

    final pageToFetch = isRefresh ? 1 : state.currentPage + 1;

    try {
      final repository = ref.read(tripsRepositoryProvider);
      final response = await repository.getHistoryOrders(
        type: type,
        status: status,
        page: pageToFetch,
        limit: limit,
      );

      final newOrders = response.data;
      final updatedOrders = isRefresh
          ? newOrders
          : [...state.historyOrders, ...newOrders];

      // If we fetched fewer items than limit, or we reached total
      final hasMore =
          newOrders.length >= limit && updatedOrders.length < response.total;

      state = state.copyWith(
        isHistoryLoading: false,
        isLoadingMore: false,
        historyResponse: response,
        historyOrders: updatedOrders,
        currentPage: pageToFetch,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isHistoryLoading: false,
        isLoadingMore: false,
        historyError: e.toString(),
      );
    }
  }
}
