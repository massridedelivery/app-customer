import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_discovery_remote_data_source.g.dart';

abstract interface class FoodDiscoveryRemoteDataSource {
  Future<HomeResponseModel> getHomeFeed({
    required double lat,
    required double lng,
  });
  Future<List<RestaurantProfileModel>> searchRestaurants({
    required String query,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
    String? category,
    bool? isOpen,
    double? maxDistance,
  });
  Future<List<CategoryModel>> getCategories();
  Future<List<RestaurantProfileModel>> getCategoryRestaurants({
    required String categoryId,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
  });
  Future<List<RestaurantProfileModel>> getSavedRestaurants({
    required double lat,
    required double lng,
  });
  Future<void> favoriteRestaurant(String restaurantId);
  Future<void> unfavoriteRestaurant(String restaurantId);
}

@Riverpod(keepAlive: true)
FoodDiscoveryRemoteDataSource foodDiscoveryRemoteDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FoodDiscoveryRemoteDataSourceImpl(apiService);
}

class FoodDiscoveryRemoteDataSourceImpl
    implements FoodDiscoveryRemoteDataSource {
  final ApiService _apiService;

  FoodDiscoveryRemoteDataSourceImpl(this._apiService);

  @override
  Future<HomeResponseModel> getHomeFeed({
    required double lat,
    required double lng,
  }) async {
    final response = await _apiService.dio.get(
      '/api/discovery/home',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return HomeResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<RestaurantProfileModel>> searchRestaurants({
    required String query,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
    String? category,
    bool? isOpen,
    double? maxDistance,
  }) async {
    final queryParams = <String, dynamic>{'q': query, 'lat': lat, 'lng': lng};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (category != null) queryParams['category'] = category;
    if (isOpen != null) queryParams['is_open'] = isOpen;
    if (maxDistance != null) queryParams['max_distance'] = maxDistance;

    final response = await _apiService.dio.get(
      '/api/discovery/search',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => RestaurantProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiService.dio.get('/api/discovery/categories');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RestaurantProfileModel>> getCategoryRestaurants({
    required String categoryId,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{'lat': lat, 'lng': lng};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.dio.get(
      '/api/discovery/categories/$categoryId',
      queryParameters: queryParams,
    );
    final dynamic data = response.data;
    if (data is List) {
      return data
          .map(
            (e) => RestaurantProfileModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } else if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map(
            (e) => RestaurantProfileModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<RestaurantProfileModel>> getSavedRestaurants({
    required double lat,
    required double lng,
  }) async {
    final response = await _apiService.dio.get(
      '/api/discovery/saved',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final dynamic data = response.data;
    final List<RestaurantProfileModel> list = [];
    final List<dynamic> items = data is List
        ? data
        : (data is Map && data['items'] is List ? data['items'] as List : []);

    for (var item in items) {
      try {
        if (item is Map) {
          final normalized = Map<String, dynamic>.from(item);
          // Normalize ID mapping
          if (!normalized.containsKey('user_id') &&
              normalized.containsKey('id')) {
            normalized['user_id'] = normalized['id'];
          }
          // Normalize name mapping
          if (!normalized.containsKey('restaurant_name') &&
              normalized.containsKey('name')) {
            normalized['restaurant_name'] = normalized['name'];
          }
          // Default lat/lng if not present
          if (!normalized.containsKey('lat')) {
            normalized['lat'] = 0.0;
          }
          if (!normalized.containsKey('lng')) {
            normalized['lng'] = 0.0;
          }

          list.add(RestaurantProfileModel.fromJson(normalized));
        }
      } catch (_) {
        // Skip malformed items silently
      }
    }
    return list;
  }

  @override
  Future<void> favoriteRestaurant(String restaurantId) async {
    await _apiService.dio.post('/api/discovery/saved/$restaurantId');
  }

  @override
  Future<void> unfavoriteRestaurant(String restaurantId) async {
    await _apiService.dio.delete('/api/discovery/saved/$restaurantId');
  }
}
