import 'package:customer_app/features/live_ride/domain/repositories/i_rating_repository.dart';
import 'package:customer_app/features/live_ride/data/repositories/rating_repository_impl.dart';
import 'package:customer_app/features/live_ride/domain/usecases/submit_rating_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_rating_usecase_impl.g.dart';

@riverpod
SubmitRatingUseCaseImpl submitRatingUseCase(Ref ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return SubmitRatingUseCaseImpl(repository);
}

class SubmitRatingUseCaseImpl implements SubmitRatingUseCase {
  final IRatingRepository _repository;

  SubmitRatingUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String jobId,
    required int rating,
    required List<String> tags,
    int? tip,
    String? comment,
  }) {
    return _repository.submitRating(
      jobId: jobId,
      rating: rating,
      tags: tags,
      tip: tip,
      comment: comment,
    );
  }
}
