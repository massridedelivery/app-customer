import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_review_controller.g.dart';

/// Submits a post-delivery review for a messenger order (SCRUM-41).
/// Fire-and-forget: idle → loading → data (success) / error, mirroring the
/// ride RatingController.
@riverpod
class MessengerReviewController extends _$MessengerReviewController {
  @override
  FutureOr<void> build() {
    // Idle/initial state
  }

  Future<void> submit({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    if (rating == 0) {
      state = AsyncValue.error(
        Exception('กรุณาให้คะแนนคนขับก่อนนะครับ'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(messengerRepositoryProvider)
          .reviewOrder(orderId, rating: rating, comment: comment);
    });
  }
}
