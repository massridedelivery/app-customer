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
      editAvatarUrl: profile.avatarUrl,
    );
  }

  /// Lets the user pick a profile photo. The picked file previews immediately;
  /// then we try to upload it for a hosted URL. The upload endpoint isn't wired
  /// yet (see [AvatarUploadService]), so for now this only previews and reports
  /// that saving the photo isn't available — the rest of the profile still saves.
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

    // Show the picked image right away.
    state = AsyncData(current.copyWith(pickedAvatarPath: image.path));

    final url = await ref.read(avatarUploadServiceProvider).uploadAvatar(image);
    final after = state.value;
    if (after == null) return;
    state = AsyncData(
      after.copyWith(
        editAvatarUrl: url ?? after.editAvatarUrl,
        error: url == null
            ? 'อัปโหลดรูปยังไม่พร้อมใช้งาน (รอ backend) — รูปแสดงตัวอย่างเท่านั้น'
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

    final result = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: fullName,
            emergencyContact: '',
            preferences: {},
            email: email,
            avatarUrl: currentState.editAvatarUrl,
          );
      return ref.read(profileRepositoryProvider).getProfile();
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
