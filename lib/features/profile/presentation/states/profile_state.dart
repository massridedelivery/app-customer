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
    // True while a picked avatar is being uploaded to storage.
    @Default(false) bool isUploadingAvatar,
    // Current avatar URL being edited (from the profile). Used for display via
    // NetworkImage. [pickedAvatarPath] is a just-picked local file shown as a
    // preview before/without a successful upload.
    String? editAvatarUrl,
    String? pickedAvatarPath,
    // file_key of a freshly uploaded avatar, sent to the backend on save as
    // `avatar_url`. Null until an upload succeeds; the backend resolves it to a
    // readable URL and echoes that back on the profile response.
    String? pendingAvatarFileKey,
    String? error,
  }) = _ProfileState;
}
