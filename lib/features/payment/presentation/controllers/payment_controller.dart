import 'package:customer_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:customer_app/features/payment/presentation/states/payment_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_controller.g.dart';

@riverpod
class PaymentController extends _$PaymentController {
  @override
  PaymentState build() {
    return const PaymentState();
  }

  Future<void> saveCard({
    required String cardToken,
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final result = await AsyncValue.guard(() async {
      await ref
          .read(paymentRepositoryProvider)
          .saveCard(cardToken: cardToken, email: email);
    });

    if (result.hasError) {
      state = state.copyWith(isLoading: false, error: result.error.toString());
    } else {
      state = state.copyWith(isLoading: false, isSuccess: true);
    }
  }

  void resetSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}
