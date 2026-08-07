import 'package:customer_app/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    required AsyncValue<ProfileEntity?> profile,
    @Default('') String editName,
    @Default('') String phone,
    @Default(false) bool isUpdating,
    // Current avatar URL being edited (from the profile, or a freshly uploaded
    // one). [pickedAvatarPath] is a just-picked local file shown as a preview
    // before/without a successful upload.
    String? editAvatarUrl,
    String? pickedAvatarPath,
    String? error,
  }) = _ProfileState;
}
