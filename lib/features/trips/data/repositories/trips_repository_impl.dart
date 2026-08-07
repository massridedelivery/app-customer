import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/domain/repositories/i_trips_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trips_repository_impl.g.dart';

// Runs in a background isolate via compute() — HistoryResponse wraps a list of
// the deeply-nested HistoryOrder, whose fromJson does enough allocation to drop
// frames if parsed on the UI isolate while the history list is scrolling.
HistoryResponse _parseHistoryResponse(Map<String, dynamic> json) =>
    HistoryResponse.fromJson(json);

@riverpod
ITripsRepository tripsRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TripsRepositoryImpl(apiService);
}

class TripsRepositoryImpl implements ITripsRepository {
  final ApiService _apiService;

  TripsRepositoryImpl(this._apiService);

  @override
  Future<HistoryResponse> getHistoryOrders({
    HistoryType? type,
    HistoryStatus? status,
    required int page,
    required int limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null) {
        queryParams['type'] = type.name.toUpperCase();
      }
      if (status != null) {
        queryParams['status'] = status.name.toUpperCase();
      }

      final response = await _apiService.dio.get(
        '/api/customer/history',
        queryParameters: queryParams,
      );
      final json = response.data as Map<String, dynamic>;
      try {
        return await compute(_parseHistoryResponse, json);
      } catch (_) {
        // Defensive: if the model can't cross the isolate boundary, fall back
        // to parsing here. Same result — just not offloaded from the UI thread.
        return _parseHistoryResponse(json);
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch history orders',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<HistoryFoodDetails> getFoodOrderDetail(String id) async {
    try {
      final response = await _apiService.dio.get(
        '/api/food/customer/orders/$id',
      );
      return HistoryFoodDetails.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch food order detail',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<HistoryRideDetails> getRideOrderDetail(String id) async {
    try {
      final response = await _apiService.dio.get('/api/customer/jobs/$id');
      return HistoryRideDetails.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch ride order detail',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
