import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_models.freezed.dart';
part 'food_models.g.dart';

@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    String? name,
    @JsonKey(name: 'name_th') String? nameTh,
    String? slug,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

Object? _readRestaurantId(Map<dynamic, dynamic> json, String fieldName) {
  return json['user_id'] ?? json['id'];
}

Object? _readRestaurantName(Map<dynamic, dynamic> json, String fieldName) {
  return json['restaurant_name'] ?? json['name'];
}

Object? _readLat(Map<dynamic, dynamic> json, String fieldName) {
  return (json['lat'] as num?)?.toDouble() ?? 0.0;
}

Object? _readLng(Map<dynamic, dynamic> json, String fieldName) {
  return (json['lng'] as num?)?.toDouble() ?? 0.0;
}

Object? _readDriverId(Map<dynamic, dynamic> json, String fieldName) {
  return json['driver_id'] ?? json['driver_info']?['id'];
}

Object? _readDriverName(Map<dynamic, dynamic> json, String fieldName) {
  return json['driver_name'] ?? json['driver_info']?['full_name'];
}

Object? _readVehiclePlate(Map<dynamic, dynamic> json, String fieldName) {
  return json['vehicle_plate'] ?? json['driver_info']?['vehicle_plate'];
}

Object? _readPromoTitle(Map<dynamic, dynamic> json, String fieldName) {
  return json['title'] ?? json['name'];
}

Object? _readPromoDiscount(Map<dynamic, dynamic> json, String fieldName) {
  return (json['discount'] as num?)?.toDouble() ??
      (json['discount_value'] as num?)?.toDouble() ??
      0.0;
}

Object? _readPromoMinOrder(Map<dynamic, dynamic> json, String fieldName) {
  return (json['min_order'] as num?)?.toDouble() ??
      (json['min_spend'] as num?)?.toDouble() ??
      0.0;
}

Object? _readPromoExpiresAt(Map<dynamic, dynamic> json, String fieldName) {
  return json['expires_at'] ?? json['valid_until'];
}

Object? _readPromoIsCollected(Map<dynamic, dynamic> json, String fieldName) {
  return json['is_collected'] ?? true;
}

@freezed
abstract class RestaurantProfileModel with _$RestaurantProfileModel {
  const factory RestaurantProfileModel({
    @JsonKey(name: 'user_id', readValue: _readRestaurantId) required String id,
    @JsonKey(name: 'restaurant_name', readValue: _readRestaurantName)
    required String restaurantName,
    @JsonKey(readValue: _readLat) required double lat,
    @JsonKey(readValue: _readLng) required double lng,
    @Default(0.0) double rating,
    @JsonKey(name: 'is_open') @Default(false) bool isOpen,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'min_order_amount') @Default(0.0) double minOrderAmount,
    @JsonKey(name: 'cuisine_type') String? cuisineType,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'verification_status') String? verificationStatus,
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'delivery_fee') double? deliveryFee,
    @JsonKey(name: 'duration_min') int? durationMin,
    @JsonKey(name: 'is_estimate') @Default(false) bool isEstimate,
    @JsonKey(name: 'is_sponsored') @Default(false) bool isSponsored,
    @Default([]) List<String> categories,
    @JsonKey(name: 'is_saved') @Default(false) bool isSaved,
  }) = _RestaurantProfileModel;

  factory RestaurantProfileModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantProfileModelFromJson(json);
}

@freezed
abstract class HomeSectionItemPromoModel with _$HomeSectionItemPromoModel {
  const factory HomeSectionItemPromoModel({String? title, String? color}) =
      _HomeSectionItemPromoModel;

  factory HomeSectionItemPromoModel.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionItemPromoModelFromJson(json);
}

@freezed
abstract class HomeSectionItemBadgeModel with _$HomeSectionItemBadgeModel {
  const factory HomeSectionItemBadgeModel({
    String? title,
    String? color,
    @JsonKey(name: 'bgColor') String? bgColor,
    String? type,
  }) = _HomeSectionItemBadgeModel;

  factory HomeSectionItemBadgeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionItemBadgeModelFromJson(json);
}

@freezed
abstract class HomeSectionItemModel with _$HomeSectionItemModel {
  const factory HomeSectionItemModel({
    required String id,
    String? title,
    String? name,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'action_type') String? actionType,
    @JsonKey(name: 'action_value') String? actionValue,
    @JsonKey(name: 'restaurant_name') String? restaurantName,
    double? rating,
    @JsonKey(name: 'is_open') bool? isOpen,
    @JsonKey(name: 'is_saved') bool? isSaved,
    @JsonKey(name: 'delivery_fee') double? deliveryFee,
    @JsonKey(name: 'duration_min') int? durationMin,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'overlay_img') String? overlayImg,
    @JsonKey(name: 'review_count') int? reviewCount,
    @Default([]) List<HomeSectionItemPromoModel> promo,
    @Default([]) List<HomeSectionItemBadgeModel> badges,
  }) = _HomeSectionItemModel;

  factory HomeSectionItemModel.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionItemModelFromJson(json);
}

@freezed
abstract class HomeSectionModel with _$HomeSectionModel {
  const factory HomeSectionModel({
    required String id,
    String? title,
    String? type,
    String? layout,
    String? description,
    @JsonKey(name: 'is_more') bool? isMore,
    @Default([]) List<HomeSectionItemModel> items,
  }) = _HomeSectionModel;

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionModelFromJson(json);
}

@freezed
abstract class HomeResponseModel with _$HomeResponseModel {
  const factory HomeResponseModel({
    @Default([]) List<CategoryModel> categories,
    @Default([]) List<HomeSectionModel> sections,
  }) = _HomeResponseModel;

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$HomeResponseModelFromJson(json);
}

@freezed
abstract class ModifierModel with _$ModifierModel {
  const factory ModifierModel({
    required String id,
    required String name,
    @Default(0.0) double price,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'modifier_group_id') String? modifierGroupId,
    @JsonKey(name: 'name_th') String? nameTh,
    @JsonKey(name: 'sort_order') int? sortOrder,
  }) = _ModifierModel;

  factory ModifierModel.fromJson(Map<String, dynamic> json) =>
      _$ModifierModelFromJson(json);
}

@freezed
abstract class ModifierGroupModel with _$ModifierGroupModel {
  const factory ModifierGroupModel({
    required String id,
    required String name,
    @JsonKey(name: 'min_select') @Default(0) int minSelect,
    @JsonKey(name: 'max_select') @Default(1) int maxSelect,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'name_th') String? nameTh,
    @JsonKey(name: 'restaurant_id') String? restaurantId,
    @Default([]) List<ModifierModel> modifiers,
  }) = _ModifierGroupModel;

  factory ModifierGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupModelFromJson(json);
}

@freezed
abstract class MenuItemModel with _$MenuItemModel {
  const factory MenuItemModel({
    required String id,
    @JsonKey(name: 'category_id') required String categoryId,
    required String name,
    @JsonKey(name: 'name_th') required String nameTh,
    required double price,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'modifier_groups')
    @Default([])
    List<ModifierGroupModel> modifierGroups,
    String? description,
    @JsonKey(name: 'restaurant_id') String? restaurantId,
    @JsonKey(name: 'original_price') double? originalPrice,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MenuItemModel;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) =>
      _$MenuItemModelFromJson(json);
}

@freezed
abstract class MenuCategoryModel with _$MenuCategoryModel {
  const factory MenuCategoryModel({
    required String id,
    required String name,
    @JsonKey(name: 'name_th') required String nameTh,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'restaurant_id') String? restaurantId,
    String? style,
    @Default([]) List<MenuItemModel> items,
  }) = _MenuCategoryModel;

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$MenuCategoryModelFromJson(json);
}

@freezed
abstract class DeliveryTierModel with _$DeliveryTierModel {
  const factory DeliveryTierModel({
    required String tier,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'delivery_fee') required double deliveryFee,
    @JsonKey(name: 'estimated_min') required int estimatedMin,
    String? description,
  }) = _DeliveryTierModel;

  factory DeliveryTierModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryTierModelFromJson(json);
}

@freezed
abstract class FareEstimateResponseModel with _$FareEstimateResponseModel {
  const factory FareEstimateResponseModel({
    @JsonKey(name: 'base_fee') required double baseFee,
    @JsonKey(name: 'distance_km') required double distanceKm,
    @JsonKey(name: 'food_total') required double foodTotal,
    @Default([]) List<DeliveryTierModel> tiers,
  }) = _FareEstimateResponseModel;

  factory FareEstimateResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateResponseModelFromJson(json);
}

@freezed
abstract class FoodOrderItemModel with _$FoodOrderItemModel {
  const factory FoodOrderItemModel({
    required String id,
    @JsonKey(name: 'menu_item_id') @Default('') String menuItemId,
    @Default('') String name,
    @Default(1) int quantity,
    @JsonKey(name: 'unit_price') @Default(0.0) double unitPrice,
    @Default(0.0) double subtotal,
    @JsonKey(name: 'selected_modifiers')
    @Default([])
    List<ModifierModel> selectedModifiers,
    @JsonKey(name: 'order_id') String? orderId,
  }) = _FoodOrderItemModel;

  factory FoodOrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$FoodOrderItemModelFromJson(json);
}

@freezed
abstract class FoodDriverInfoModel with _$FoodDriverInfoModel {
  const factory FoodDriverInfoModel({
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
    double? rating,
    @JsonKey(name: 'vehicle_plate') String? vehiclePlate,
    @JsonKey(name: 'vehicle_color') String? vehicleColor,
    @JsonKey(name: 'vehicle_model') String? vehicleModel,
  }) = _FoodDriverInfoModel;

  factory FoodDriverInfoModel.fromJson(Map<String, dynamic> json) =>
      _$FoodDriverInfoModelFromJson(json);
}

@freezed
abstract class FoodOrderModel with _$FoodOrderModel {
  const factory FoodOrderModel({
    required String id,
    @Default('PLACED') String status,
    @JsonKey(name: 'restaurant_id') @Default('') String restaurantId,
    @JsonKey(name: 'food_total') @Default(0.0) double foodTotal,
    @JsonKey(name: 'delivery_fee') @Default(0.0) double deliveryFee,
    @JsonKey(name: 'promo_discount') @Default(0.0) double promoDiscount,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @JsonKey(name: 'payment_method') @Default('CASH') String paymentMethod,
    @Default('STANDARD') String tier,
    @JsonKey(name: 'delivery_lat') @Default(0.0) double deliveryLat,
    @JsonKey(name: 'delivery_lng') @Default(0.0) double deliveryLng,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    @JsonKey(name: 'delivery_notes') String? deliveryNotes,
    @Default([]) List<FoodOrderItemModel> items,
    @JsonKey(name: 'placed_at') @Default('') String placedAt,
    @JsonKey(name: 'driver_id', readValue: _readDriverId) String? driverId,
    @JsonKey(name: 'driver_name', readValue: _readDriverName) String? driverName,
    @JsonKey(name: 'vehicle_plate', readValue: _readVehiclePlate) String? vehiclePlate,
    
    // Additional fields matching backend JSON
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'restaurant_name') String? restaurantName,
    @JsonKey(name: 'restaurant_address') String? restaurantAddress,
    @JsonKey(name: 'restaurant_lat') double? restaurantLat,
    @JsonKey(name: 'restaurant_lng') double? restaurantLng,
    @JsonKey(name: 'customer_distance_km') double? customerDistanceKm,
    @JsonKey(name: 'fulfillment_distance_km') double? fulfillmentDistanceKm,
    @JsonKey(name: 'delay_queue_until') String? delayQueueUntil,
    @JsonKey(name: 'prep_time_adjustment_min') int? prepTimeAdjustmentMin,
    @JsonKey(name: 'original_total_amount') double? originalTotalAmount,
    @JsonKey(name: 'promo_min_spend') double? promoMinSpend,
    @JsonKey(name: 'batching_enabled') bool? batchingEnabled,
    @JsonKey(name: 'platform_commission') double? platformCommission,
    @JsonKey(name: 'driver_info') FoodDriverInfoModel? driverInfo,
    String? polyline,
  }) = _FoodOrderModel;

  factory FoodOrderModel.fromJson(Map<String, dynamic> json) =>
      _$FoodOrderModelFromJson(json);
}

@freezed
abstract class FoodOrderReviewResponseModel with _$FoodOrderReviewResponseModel {
  const factory FoodOrderReviewResponseModel({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    required int rating,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _FoodOrderReviewResponseModel;

  factory FoodOrderReviewResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FoodOrderReviewResponseModelFromJson(json);
}

@freezed
abstract class PromoModel with _$PromoModel {
  const factory PromoModel({
    required String id,
    required String code,
    @JsonKey(readValue: _readPromoTitle) required String title,
    required String description,
    @JsonKey(readValue: _readPromoDiscount) required double discount,
    @JsonKey(name: 'min_order', readValue: _readPromoMinOrder)
    required double minOrder,
    @JsonKey(name: 'expires_at', readValue: _readPromoExpiresAt)
    required String expiresAt,
    @JsonKey(name: 'is_collected', readValue: _readPromoIsCollected)
    required bool isCollected,
    int? color,
    String? tag,
    @JsonKey(name: 'sub_tag') String? subTag,
  }) = _PromoModel;

  factory PromoModel.fromJson(Map<String, dynamic> json) =>
      _$PromoModelFromJson(json);
}

@freezed
abstract class PromoValidateResponseModel with _$PromoValidateResponseModel {
  const factory PromoValidateResponseModel({
    @JsonKey(name: 'discount_amount') required double discountAmount,
    @JsonKey(name: 'final_fare') required double finalFare,
    @JsonKey(name: 'is_valid') required bool isValid,
    String? message,
  }) = _PromoValidateResponseModel;

  factory PromoValidateResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PromoValidateResponseModelFromJson(json);
}

@freezed
abstract class PromoSuggestionPromoModel with _$PromoSuggestionPromoModel {
  const factory PromoSuggestionPromoModel({
    required String code,
    required String scope,
    @JsonKey(name: 'min_spend') required double minSpend,
    @Default(false) bool stackable,
  }) = _PromoSuggestionPromoModel;

  factory PromoSuggestionPromoModel.fromJson(Map<String, dynamic> json) =>
      _$PromoSuggestionPromoModelFromJson(json);
}

@freezed
abstract class PromoSuggestionModel with _$PromoSuggestionModel {
  const factory PromoSuggestionModel({
    required PromoSuggestionPromoModel promo,
    required String status,
    @Default(false) bool recommended,
    @JsonKey(name: 'amount_needed') double? amountNeeded,
  }) = _PromoSuggestionModel;

  factory PromoSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$PromoSuggestionModelFromJson(json);
}

@freezed
abstract class PromoSuggestionsResponseModel with _$PromoSuggestionsResponseModel {
  const factory PromoSuggestionsResponseModel({
    @Default([]) List<PromoSuggestionModel> suggestions,
  }) = _PromoSuggestionsResponseModel;

  factory PromoSuggestionsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PromoSuggestionsResponseModelFromJson(json);
}

@freezed
abstract class StackedPromoAppliedModel with _$StackedPromoAppliedModel {
  const factory StackedPromoAppliedModel({
    required String code,
    required String scope,
    @JsonKey(name: 'discount_amount') required double discountAmount,
  }) = _StackedPromoAppliedModel;

  factory StackedPromoAppliedModel.fromJson(Map<String, dynamic> json) =>
      _$StackedPromoAppliedModelFromJson(json);
}

@freezed
abstract class StackedPromoValidationResponseModel with _$StackedPromoValidationResponseModel {
  const factory StackedPromoValidationResponseModel({
    @Default([]) List<StackedPromoAppliedModel> applied,
    @JsonKey(name: 'total_discount') required double totalDiscount,
    @JsonKey(name: 'final_amount') required double finalAmount,
  }) = _StackedPromoValidationResponseModel;

  factory StackedPromoValidationResponseModel.fromJson(Map<String, dynamic> json) =>
      _$StackedPromoValidationResponseModelFromJson(json);
}

// =============================================================================
// Legacy models for mock screen / search view compatibility
// =============================================================================

@freezed
abstract class RestaurantModel with _$RestaurantModel {
  const factory RestaurantModel({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required String deliveryTime,
    required double deliveryFee,
    required double distance,
    @Default([]) List<String> categories,
  }) = _RestaurantModel;

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantModelFromJson(json);
}

@freezed
abstract class FoodItemModel with _$FoodItemModel {
  const factory FoodItemModel({
    required String id,
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    required String imageUrl,
    required RestaurantModel restaurant,
    @Default(false) bool isAvailable,
    @Default([]) List<String> tags,
  }) = _FoodItemModel;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$FoodItemModelFromJson(json);
}
