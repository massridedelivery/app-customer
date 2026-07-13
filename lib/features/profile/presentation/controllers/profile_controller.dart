import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/features/profile/presentation/states/profile_state.dart';
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
