import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

/// Mirrors the `GET`/`PUT /api/customer/profile` response body. Both endpoints
/// return the same full profile object. Fields beyond the original
/// `user_id`/`full_name`/`phone`/`rating`/`avatar_url` are nullable so older
/// backends that omit them still parse.
@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'full_name') required String fullName,
    required String phone,
    required double rating,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? email,
    @JsonKey(name: 'emergency_contact') String? emergencyContact,
    Map<String, dynamic>? preferences,
    @JsonKey(name: 'total_trips') int? totalTrips,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'joined_date_thai') String? joinedDateThai,
    @JsonKey(name: 'saved_places') List<Place>? savedPlaces,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}
