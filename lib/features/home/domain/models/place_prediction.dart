import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_prediction.freezed.dart';
part 'place_prediction.g.dart';

/// A single Google Places Autocomplete prediction.
///
/// It intentionally has no coordinates — those are resolved lazily via a
/// Place Details lookup (`placeId`) only when the user selects the item.
@freezed
abstract class PlacePrediction with _$PlacePrediction {
  const factory PlacePrediction({
    @JsonKey(name: 'place_id') required String placeId,
    @Default('') String description,
    @JsonKey(name: 'main_text') @Default('') String mainText,
    @JsonKey(name: 'secondary_text') @Default('') String secondaryText,
    @JsonKey(name: 'distance_meters') int? distanceMeters,
  }) = _PlacePrediction;

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      _$PlacePredictionFromJson(json);
}
