import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/features/profile/data/services/avatar_upload_service.dart';
import 'package:customer_app/features/profile/presentation/states/profile_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  Timer? _debounceTimer;

  @override
  FutureOr<ProfileState> build() async {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    final profile = await ref.read(profileRepositoryProvider).getProfile();
    return ProfileState(
      profile: AsyncData(profile),
      editName: profile.fullName,
      phone: profile.phone,
      editAvatarUrl: profile.avatarUrl,
    );
  }

  /// Lets the user pick a profile photo. The picked file previews immediately,
  /// then uploads to storage (via the presigned-URL flow in
  /// [AvatarUploadService]) to obtain a hosted `avatar_url`, which is persisted
  /// on the next profile save. If the upload fails the local preview stays and
  /// we surface an error; the rest of the profile still saves.
  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    final current = state.value;
    if (current == null) return;

    // Show the picked image right away and mark the upload as in flight.
    state = AsyncData(
      current.copyWith(pickedAvatarPath: image.path, isUploadingAvatar: true),
    );

    // uploadAvatar returns the file_key to persist as avatar_url on save; the
    // just-picked local file (pickedAvatarPath) covers the on-screen preview
    // until the backend echoes back a resolved URL.
    final fileKey = await ref
        .read(avatarUploadServiceProvider)
        .uploadAvatar(image);
    final after = state.value;
    if (after == null) return;
    state = AsyncData(
      after.copyWith(
        pendingAvatarFileKey: fileKey ?? after.pendingAvatarFileKey,
        isUploadingAvatar: false,
        error: fileKey == null
            ? 'อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'
            : null,
      ),
    );
  }

  void updateEditName(String name) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      final currentState = state.value;
      if (currentState == null) return;

      state = AsyncData(currentState.copyWith(editName: name));
    });
  }

  Future<void> updateProfile({required String fullName, String? email}) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(isUpdating: true));

    // PUT echoes back the full profile, so use its response directly instead of
    // issuing a follow-up GET.
    final result = await AsyncValue.guard(() async {
      return ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: fullName,
            emergencyContact: '',
            preferences: {},
            email: email,
            // Send the freshly-uploaded file_key when present; the backend
            // resolves it to a URL. Fall back to the existing avatar so an
            // unchanged avatar isn't dropped.
            avatarUrl:
                currentState.pendingAvatarFileKey ?? currentState.editAvatarUrl,
          );
    });

    state = AsyncData(
      currentState.copyWith(
        profile: result.whenData((p) => p),
        isUpdating: false,
        error: result.error?.toString(),
      ),
    );
  }
}
