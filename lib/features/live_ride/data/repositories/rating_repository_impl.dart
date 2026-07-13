import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/live_ride/domain/repositories/i_rating_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rating_repository_impl.g.dart';

@riverpod
IRatingRepository ratingRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RatingRepositoryImpl(apiService);
}

class RatingRepositoryImpl implements IRatingRepository {
  final ApiService _apiService;

  RatingRepositoryImpl(this._apiService);

  @override
  Future<void> submitRating({
    required String jobId,
    required int rating,
    required List<String> tags,
    int? tip,
    String? comment,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/customer/jobs/$jobId/rate',
        data: {
          'rating': rating,
          'tags': tags,
          'tip': ?tip,
          if (comment != null && comment.isNotEmpty) 'comment': comment.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit rating');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
