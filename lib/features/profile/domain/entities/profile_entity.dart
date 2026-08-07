import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String userId,
    required String fullName,
    required String phone,
    required double rating,
    String? avatarUrl,
    String? email,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
    int? totalTrips,
    String? createdAt,
    String? joinedDateThai,
    @Default(<Place>[]) List<Place> savedPlaces,
  }) = _ProfileEntity;
}
