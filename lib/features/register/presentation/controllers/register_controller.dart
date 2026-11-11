import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  FutureOr<void> build() {
    // Return nothing (void) on success/initial state
  }

  Future<void> register({required String fullName, String? email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(fullName: fullName, email: email);
      // No device registration here: PushNotificationService registers the
      // FCM token once the session flips to authenticated (setAuthenticated).
    });
  }
}
