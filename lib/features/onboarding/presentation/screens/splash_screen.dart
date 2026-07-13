import 'dart:math' as math;
import 'dart:ui';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale75,
      body: Stack(
        children: [
          // Aura Blurs
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: _AuraBlur(
              color: AppColors.deepBlue,
              size: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: -MediaQuery.of(context).size.width * 0.2,
            child: _AuraBlur(
              color: Colors.blue,
              size: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.05,
            left: MediaQuery.of(context).size.width * 0.1,
            child: _AuraBlur(
              color: AppColors.lightBlue,
              size: MediaQuery.of(context).size.width * 0.6,
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Transform.rotate(
                  angle: -6 * math.pi / 180,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.deepBlue, AppColors.darkestBlue],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.motion_photos_on_outlined,
                      color: AppColors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Title
                Text(
                  'MassMove',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepBlue,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'ยกระดับการให้บริการในเมือง',
                  style: AppTypography.label2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraBlur extends StatelessWidget {
  final Color color;
  final double size;

  const _AuraBlur({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
