import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brand-red splash: the white MASS MOVE logo dead centre at 150dp — the same
/// red, logo, size and position as the native splash (flutter_native_splash in
/// pubspec.yaml), so the system splash flows straight into this one — plus
/// loading dots and the services line at the bottom.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    // Resolve location as soon as the app opens (iOS + Android): creating
    // the keep-alive HomeController starts its location bootstrap, so the
    // current location is usually ready by the time home appears. On the
    // first run the onboarding's last page does this instead, so the system
    // permission dialog comes after the explanation rather than over the
    // splash.
    if (ref.read(appStorageProvider).hasCompletedOnboarding) {
      ref.read(homeControllerProvider);
    }
    // Is this build behind the store's? If so the router holds the app on the
    // update screen; runs in the background, never delaying the splash.
    ref.read(forceUpdateProvider.notifier).check();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Mark splash as shown. This will trigger the router's redirect logic
    // and move the user to the appropriate screen (main, auth, or onboarding).
    ref.read(routerNotifierProvider).splashShown = true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandIconRed,
        body: Stack(
          children: [
            // Exactly centred, like the native splash's logo.
            Center(
              child: Image.asset(
                'assets/icon/splash_logo.png',
                width: 150,
                semanticLabel: 'Mass Move',
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64 + MediaQuery.paddingOf(context).bottom,
              child: Column(
                children: [
                  _LoadingDots(animation: _dots),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.splashServices,
                    style: AppTypography.body2.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three white dots; a brighter one sweeps left to right.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final lead = (animation.value * 3).floor() % 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final behind = (lead - i) % 3; // 0 = lit, then fading
            final alpha = const [1.0, 0.3, 0.55][behind];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: alpha),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
