import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_receipt_state.freezed.dart';

@freezed
abstract class FoodReceiptState with _$FoodReceiptState {
  const factory FoodReceiptState({
    @Default(true) bool isLoading,
    FoodOrderModel? order,
    String? error,
  }) = _FoodReceiptState;
}
