import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

@freezed
abstract class Place with _$Place {
  const factory Place({
    String? id,
    required String name,
    required double lat,
    required double lng,
    String? address,
    @JsonKey(name: 'is_default') bool? isDefault,
    String? note,
    @JsonKey(name: 'place_id') String? placeId,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}
