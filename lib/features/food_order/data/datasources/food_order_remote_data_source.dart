import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/domain/models/remote_cart.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_order_remote_data_source.g.dart';

abstract interface class FoodOrderRemoteDataSource {
  Future<RestaurantProfileModel> getRestaurantProfile(String id);
  Future<List<MenuCategoryModel>> getRestaurantMenu(String id);
  Future<FareEstimateResponseModel> getFareEstimate({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
  });
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
  });
  Future<void> upsertCart({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
  });
  Future<RemoteCart> getCart();
  Future<FoodOrderModel> getOrderDetail(String id);
  Future<void> cancelOrder(String id);
  Future<FoodOrderReviewResponseModel> submitReview({
    required String orderId,
    required int rating,
    String? comment,
    bool? isAnonymous,
    List<Map<String, dynamic>>? itemReviews,
  });
  Future<List<RestaurantProfileModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
  });
  Future<List<Place>> getSavedPlaces();
  Future<Place> addSavedPlace({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? note,
  });
  Future<void> deleteSavedPlace(String id);
  Future<Place> pinSnap({required double lat, required double lng});
  Future<List<PromoModel>> getPromoList();
  Future<List<PromoModel>> getPromoContext({
    required String appliesTo,
    String? merchantId,
  });
  Future<List<PromoSuggestionModel>> getPromoSuggestions({
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  });
  Future<PromoValidateResponseModel> validatePromoCode({
    required String code,
    required double fare,
  });
  Future<StackedPromoValidationResponseModel> validateStackedPromos({
    required List<String> promoCodes,
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  });
  Future<List<FoodOrderModel>> getOrdersList();
  Future<List<ChatMessage>> getOrderChat(
    String orderId, {
    int limit = 50,
    String? before,
  });
  Future<ChatMessage> sendOrderChatMessage(
    String orderId, {
    required String text,
    required String msgType,
  });
}

@riverpod
FoodOrderRemoteDataSource foodOrderRemoteDataSource(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FoodOrderRemoteDataSourceImpl(apiService);
}

class FoodOrderRemoteDataSourceImpl implements FoodOrderRemoteDataSource {
  final ApiService _apiService;

  FoodOrderRemoteDataSourceImpl(this._apiService);

  @override
  Future<RestaurantProfileModel> getRestaurantProfile(String id) async {
    final response = await _apiService.dio.get(
      '/api/food/customer/restaurants/$id',
    );
    return RestaurantProfileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<MenuCategoryModel>> getRestaurantMenu(String id) async {
    final response = await _apiService.dio.get(
      '/api/food/customer/restaurants/$id/menu',
    );
    final data = response.data as Map<String, dynamic>;
    final categories = data['categories'] as List<dynamic>? ?? [];
    return categories
        .map((e) => MenuCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FareEstimateResponseModel> getFareEstimate({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double lat,
    required double lng,
  }) async {
    final response = await _apiService.dio.post(
      '/api/food/customer/estimate',
      data: {
        'restaurant_id': restaurantId,
        'items': items,
        'delivery_lat': lat,
        'delivery_lng': lng,
      },
    );
    return FareEstimateResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
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
    final body = <String, dynamic>{
      'restaurant_id': restaurantId,
      'items': items,
      'delivery_lat': lat,
      'delivery_lng': lng,
    };
    if (address != null) body['delivery_address'] = address;
    if (notes != null) body['delivery_notes'] = notes;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (tier != null) body['tier'] = tier;
    if (promoCodes != null) body['promo_codes'] = promoCodes;
    if (idempotencyKey != null) body['idempotency_key'] = idempotencyKey;

    final response = await _apiService.dio.post(
      '/api/food/customer/orders',
      data: body,
    );
    return FoodOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> upsertCart({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
  }) async {
    // PUT upserts the whole cart (SCRUM-44 Screen 4); switching restaurant
    // clears it server-side.
    await _apiService.dio.put(
      '/api/food/customer/cart',
      data: {'restaurant_id': restaurantId, 'items': items},
    );
  }

  @override
  Future<RemoteCart> getCart() async {
    final response = await _apiService.dio.get('/api/food/customer/cart');
    final data = response.data;
    if (data is! Map<String, dynamic>) return const RemoteCart();
    return RemoteCart.fromJson(data);
  }

  @override
  Future<FoodOrderModel> getOrderDetail(String id) async {
    final response = await _apiService.dio.get('/api/food/customer/orders/$id');
    return FoodOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancelOrder(String id) async {
    await _apiService.dio.post('/api/food/customer/orders/$id/cancel');
  }

  @override
  Future<FoodOrderReviewResponseModel> submitReview({
    required String orderId,
    required int rating,
    String? comment,
    bool? isAnonymous,
    List<Map<String, dynamic>>? itemReviews,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (comment != null) body['comment'] = comment;
    if (isAnonymous != null) body['is_anonymous'] = isAnonymous;
    if (itemReviews != null) body['item_reviews'] = itemReviews;

    final response = await _apiService.dio.post(
      '/api/food/customer/orders/$orderId/review',
      data: body,
    );
    return FoodOrderReviewResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<RestaurantProfileModel>> getNearbyRestaurants({
    required double lat,
    required double lng,
  }) async {
    final response = await _apiService.dio.get(
      '/api/food/customer/restaurants/nearby',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => RestaurantProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Place>> getSavedPlaces() async {
    final response = await _apiService.dio.get('/api/customer/places');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Place> addSavedPlace({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? note,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/places',
      data: {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        // ignore: use_null_aware_elements
        if (note != null) 'note': note,
      },
    );
    return Place.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSavedPlace(String id) async {
    await _apiService.dio.delete('/api/customer/places/$id');
  }

  @override
  Future<Place> pinSnap({required double lat, required double lng}) async {
    final response = await _apiService.dio.get(
      '/api/customer/pin-snap',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final data = response.data as Map<String, dynamic>;
    return Place(
      id: data['id']?.toString(),
      name:
          data['name']?.toString() ??
          data['address']?.toString() ??
          'Snapped Position',
      address: data['address']?.toString(),
      lat: (data['lat'] as num?)?.toDouble() ?? lat,
      lng: (data['lng'] as num?)?.toDouble() ?? lng,
    );
  }

  @override
  Future<List<PromoModel>> getPromoList() async {
    final response = await _apiService.dio.get('/api/customer/promo/list');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => PromoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PromoModel>> getPromoContext({
    required String appliesTo,
    String? merchantId,
  }) async {
    final response = await _apiService.dio.get(
      '/api/customer/promos/context',
      queryParameters: {
        'applies_to': appliesTo,
        // ignore: use_null_aware_elements
        if (merchantId != null) 'merchant_id': merchantId,
      },
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => PromoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PromoSuggestionModel>> getPromoSuggestions({
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/promos/suggest',
      data: {
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'applies_to': 'FOOD',
        'restaurant_id': restaurantId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];
    return suggestions
        .map((e) => PromoSuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StackedPromoValidationResponseModel> validateStackedPromos({
    required List<String> promoCodes,
    required double subtotal,
    required double deliveryFee,
    required String restaurantId,
  }) async {
    final response = await _apiService.dio.post(
      '/api/customer/promos/validate',
      data: {
        'promo_codes': promoCodes,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'applies_to': 'FOOD',
        'restaurant_id': restaurantId,
      },
    );
    return StackedPromoValidationResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<PromoValidateResponseModel> validatePromoCode({
    required String code,
    required double fare,
  }) async {
    final response = await _apiService.dio.get(
      '/api/customer/promo/validate',
      queryParameters: {'code': code, 'fare': fare},
    );
    return PromoValidateResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<FoodOrderModel>> getOrdersList() async {
    final response = await _apiService.dio.get('/api/food/customer/orders');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => FoodOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getOrderChat(
    String orderId, {
    int limit = 50,
    String? before,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (before != null) queryParams['before'] = before;

    final response = await _apiService.dio.get(
      '/api/food/customer/orders/$orderId/chat',
      queryParameters: queryParams,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> sendOrderChatMessage(
    String orderId, {
    required String text,
    required String msgType,
  }) async {
    final response = await _apiService.dio.post(
      '/api/food/customer/orders/$orderId/chat',
      data: {'text': text, 'msg_type': msgType},
    );
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  }
}
