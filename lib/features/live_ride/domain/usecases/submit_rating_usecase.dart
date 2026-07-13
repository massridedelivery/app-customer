abstract interface class SubmitRatingUseCase {
  Future<void> call({
    required String jobId,
    required int rating,
    required List<String> tags,
    int? tip,
    String? comment,
  });
}
