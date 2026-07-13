abstract interface class IRatingRepository {
  Future<void> submitRating({
    required String jobId,
    required int rating,
    required List<String> tags,
    int? tip,
    String? comment,
  });
}
