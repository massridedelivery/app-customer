import 'package:customer_app/features/live_ride/domain/usecases/submit_rating_usecase_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rating_controller.g.dart';

@riverpod
class RatingController extends _$RatingController {
  @override
  FutureOr<void> build() {
    // Idle/initial state
  }

  Future<void> submitRating({
    required String jobId,
    required int rating,
    required List<String> tags,
    int? tip,
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
          .read(submitRatingUseCaseProvider)
          .call(
            jobId: jobId,
            rating: rating,
            tags: tags,
            tip: tip,
            comment: comment,
          );
    });
  }
}
