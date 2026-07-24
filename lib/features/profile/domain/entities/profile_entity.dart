import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String userId,
    required String fullName,
    required String phone,
    required double rating,
  }) = _ProfileEntity;
}
