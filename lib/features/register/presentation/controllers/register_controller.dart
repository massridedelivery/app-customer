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

  Future<void> registerNotification() async {
    final deviceType = PlatformUtils.devicePlatform.toLowerCase();
    final token = ref.read(tokenStorageProvider).getAccessToken();
    if (token == null) {
      throw Exception('Token is null');
    }
    await ref
        .read(registerRepositoryProvider)
        .registerDevice(token: token, deviceType: deviceType);
  }
}
