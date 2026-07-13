import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'live_food_tracking_state.freezed.dart';

@freezed
abstract class LiveFoodTrackingState with _$LiveFoodTrackingState {
  const factory LiveFoodTrackingState({
    String? orderId,
    @Default('PLACED') String orderStatus,
    LatLng? driverLocation,
    LatLng? restaurantLocation,
    String? driverId,
    String? driverName,
    String? vehiclePlate,
    String? vehicleColor,
    String? error,
    @Default(false) bool isLoading,
    FoodOrderModel? order,
  }) = _LiveFoodTrackingState;
}
