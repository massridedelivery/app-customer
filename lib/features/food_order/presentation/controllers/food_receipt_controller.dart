import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/presentation/states/food_receipt_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_receipt_controller.g.dart';

@riverpod
class FoodReceiptController extends _$FoodReceiptController {
  @override
  FoodReceiptState build(String orderId) {
    Future.microtask(() => loadReceipt(orderId));
    return const FoodReceiptState();
  }

  Future<void> loadReceipt(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final order = await repo.getOrderDetail(orderId);
      state = state.copyWith(isLoading: false, order: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
