import 'package:customer_app/core/constants/platform_utils.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/features/register/data/repositories/register_repository_impl.dart';
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
      await registerNotification();
    });
  }

  /// Best-effort device/push-token registration. A failure here (missing token,
  /// or the push endpoint being down) must NOT fail sign-up — the user is
  /// already authenticated from the OTP step, so never block app entry on it.
  Future<void> registerNotification() async {
    try {
      final deviceType = PlatformUtils.devicePlatform.toLowerCase();
      final token = ref.read(tokenStorageProvider).getAccessToken();
      if (token == null) return;
      await ref
          .read(registerRepositoryProvider)
          .registerDevice(token: token, deviceType: deviceType);
    } catch (_) {
      // swallow — push-token registration is not critical to sign-up
    }
  }
}
