import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/error/food_delivery_exception.dart';
import 'package:customer_app/features/food_order/data/datasources/food_order_remote_data_source.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/domain/models/remote_cart.dart';
import 'package:customer_app/features/food_order/domain/repositories/i_food_order_repository.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_order_repository_impl.g.dart';

@riverpod
IFoodOrderRepository foodOrderRepository(Ref ref) {
  final dataSource = ref.watch(foodOrderRemoteDataSourceProvider);
  return FoodOrderRepositoryImpl(dataSource);
}

class FoodOrderRepositoryImpl implements IFoodOrderRepository {
  final FoodOrderRemoteDataSource _dataSource;

  FoodOrderRepositoryImpl(this._dataSource);

  @override
  Future<RestaurantProfileModel> getRestaurantProfile(String id) async {
    try {
      return await _dataSource.getRestaurantProfile(id);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load restaurant profile');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MenuCategoryModel>> getRestaurantMenu(String id) async {
    try {
      return await _dataSource.getRestaurantMenu(id);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load restaurant menu');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FareEstimateResponseModel> getFareEstimate({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
  }) async {
    try {
      return await _dataSource.getFareEstimate(
        restaurantId: restaurantId,
        items: items,
        lat: lat,
        lng: lng,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to get fare estimate');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FoodOrderModel> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
    String? address,
    String? notes,
    String? paymentMethod,
    String? tier,
    List<String>? promoCodes,
    String? idempotencyKey,
  }) async {
    try {
      return await _dataSource.placeOrder(
        restaurantId: restaurantId,
        items: items,
        lat: lat,
        lng: lng,
        address: address,
        notes: notes,
        paymentMethod: paymentMethod,
        tier: tier,
        promoCodes: promoCodes,
        idempotencyKey: idempotencyKey,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to place order');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> upsertCart({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _dataSource.upsertCart(restaurantId: restaurantId, items: items);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to sync cart');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RemoteCart> getCart() async {
    try {
      return await _dataSource.getCart();
    } on DioException catch (e) {
      // No persisted cart (e.g. 404) is not an error — treat as empty.
      if (e.response?.statusCode == 404) return const RemoteCart();
      throw mapDioErrorToException(e, 'Failed to load cart');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FoodOrderModel> getOrderDetail(String id) async {
    try {
      return await _dataSource.getOrderDetail(id);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load order detail');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelOrder(String id) async {
    try {
      await _dataSource.cancelOrder(id);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to cancel order');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FoodOrderReviewResponseModel> submitReview({
    required String orderId,
    required int rating,
    String? comment,
    bool? isAnonymous,
    List<Map<String, dynamic>>? itemReviews,
  }) async {
    try {
      return await _dataSource.submitReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
        isAnonymous: isAnonymous,
        itemReviews: itemReviews,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to submit review');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RestaurantProfileModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
  }) async {
    try {
      return await _dataSource.getNearbyRestaurants(lat: lat, lng: lng);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load nearby restaurants');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Place>> getSavedPlaces() async {
    try {
      return await _dataSource.getSavedPlaces();
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load saved places');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Place> addSavedPlace({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? note,
  }) async {
    try {
      return await _dataSource.addSavedPlace(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        note: note,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to add saved place');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteSavedPlace(String id) async {
    try {
      await _dataSource.deleteSavedPlace(id);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to delete saved place');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Place> pinSnap({required double lat, required double lng}) async {
    try {
      return await _dataSource.pinSnap(lat: lat, lng: lng);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to snap pin');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PromoModel>> getPromoList() async {
    try {
      return await _dataSource.getPromoList();
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load promo list');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PromoModel>> getPromoContext({
    required String appliesTo,
    String? merchantId,
  }) async {
    try {
      return await _dataSource.getPromoContext(
        appliesTo: appliesTo,
        merchantId: merchantId,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load promo context');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PromoSuggestionModel>> getPromoSuggestions({
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async {
    try {
      return await _dataSource.getPromoSuggestions(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        restaurantId: restaurantId,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load promo suggestions');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StackedPromoValidationResponseModel> validateStackedPromos({
    required List<String> promoCodes,
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async {
    try {
      return await _dataSource.validateStackedPromos(
        promoCodes: promoCodes,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        restaurantId: restaurantId,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to validate stacked promos');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PromoValidateResponseModel> validatePromoCode({
    required String code,
    required double fare,
  }) async {
    try {
      return await _dataSource.validatePromoCode(code: code, fare: fare);
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to validate promo code');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<FoodOrderModel>> getOrdersList() async {
    try {
      return await _dataSource.getOrdersList();
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load orders list');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ChatMessage>> getOrderChat(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      return await _dataSource.getOrderChat(
        orderId,
        limit: limit,
        before: before,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to load order chat');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatMessage> sendOrderChatMessage(
    String orderId, {
    required String text,
    required String msgType,
  }) async {
    try {
      return await _dataSource.sendOrderChatMessage(
        orderId,
        text: text,
        msgType: msgType,
      );
    } on DioException catch (e) {
      throw mapDioErrorToException(e, 'Failed to send chat message');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
