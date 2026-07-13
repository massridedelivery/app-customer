import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/food_rating_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_rating_controller.g.dart';

@riverpod
class FoodRatingController extends _$FoodRatingController {
  @override
  FoodRatingState build(String orderId) {
    Future.microtask(() => loadOrderDetails(orderId));
    return const FoodRatingState();
  }

  Future<void> loadOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final order = await repo.getOrderDetail(orderId);
      
      RestaurantProfileModel? restaurant;
      try {
        restaurant = await repo.getRestaurantProfile(order.restaurantId);
      } catch (e) {
        // Safe to ignore if fails, will fallback
      }

      state = state.copyWith(
        isLoading: false,
        order: order,
        restaurant: restaurant,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitReview({
    required int rating,
    required String comment,
    required bool isAnonymous,
    required List<Map<String, dynamic>> itemReviews,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      await repo.submitReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
        isAnonymous: isAnonymous,
        itemReviews: itemReviews,
      );
      state = state.copyWith(isSubmitting: false, isSubmitSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}
