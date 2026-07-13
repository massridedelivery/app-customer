import 'package:customer_app/core/managers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  int build() {
    return 0; // Current page index
  }

  void onPageChanged(int index) {
    state = index;
  }

  Future<void> completeOnboarding() async {
    await ref.read(appStorageProvider).setHasCompletedOnboarding(true);
  }
}
