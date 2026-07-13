import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/error/food_delivery_exception.dart';
import 'package:customer_app/features/food_delivery/data/datasources/food_discovery_remote_data_source.dart';
import 'package:customer_app/features/food_delivery/domain/repositories/i_food_discovery_repository.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_discovery_repository_impl.g.dart';

@Riverpod(keepAlive: true)
IFoodDiscoveryRepository foodDiscoveryRepository(Ref ref) {
  final dataSource = ref.watch(foodDiscoveryRemoteDataSourceProvider);
  return FoodDiscoveryRepositoryImpl(dataSource);
}

class FoodDiscoveryRepositoryImpl implements IFoodDiscoveryRepository {
  final FoodDiscoveryRemoteDataSource _dataSource;

  FoodDiscoveryRepositoryImpl(this._dataSource);

  @override
  Future<HomeResponseModel> getHomeFeed({
    required double lat,
    required double lng,
  }) async {
    try {
      return await _dataSource.getHomeFeed(lat: lat, lng: lng);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load home feed');
    } catch (e) {
      throw ServerException(e.toString());
    }
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
    try {
      return await _dataSource.searchRestaurants(
        query: query,
        lat: lat,
        lng: lng,
        limit: limit,
        offset: offset,
        category: category,
        isOpen: isOpen,
        maxDistance: maxDistance,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Search failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      return await _dataSource.getCategories();
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load categories');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RestaurantProfileModel>> getCategoryRestaurants({
    required String categoryId,
    required double lat,
    required double lng,
    int? limit,
    int? offset,
  }) async {
    try {
      return await _dataSource.getCategoryRestaurants(
        categoryId: categoryId,
        lat: lat,
        lng: lng,
        limit: limit,
        offset: offset,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load category restaurants');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RestaurantProfileModel>> getSavedRestaurants({
    required double lat,
    required double lng,
  }) async {
    try {
      return await _dataSource.getSavedRestaurants(lat: lat, lng: lng);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load saved restaurants');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> favoriteRestaurant(String restaurantId) async {
    try {
      await _dataSource.favoriteRestaurant(restaurantId);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to favorite restaurant');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> unfavoriteRestaurant(String restaurantId) async {
    try {
      await _dataSource.unfavoriteRestaurant(restaurantId);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to unfavorite restaurant');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
