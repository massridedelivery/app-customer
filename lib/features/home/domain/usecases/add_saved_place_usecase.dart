abstract class AddSavedPlaceUseCase {
  Future<void> call({
    required String name,
    required double lat,
    required double lng,
    String? address,
    bool? isDefault,
    String? id,
    String? note,
    String? phoneNumber,
  });
}
