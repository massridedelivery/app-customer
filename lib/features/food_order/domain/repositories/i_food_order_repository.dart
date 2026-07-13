import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/domain/models/remote_cart.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';

abstract interface class IFoodOrderRepository {
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
  /// PUT /api/food/customer/cart — upsert the whole cart (SCRUM-44 Screen 4).
  Future<void> upsertCart({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
  });

  /// GET /api/food/customer/cart — the persisted cart (thin items). Empty when
  /// there is none.
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

  // Extra endpoints from Food Delivery Flow
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
