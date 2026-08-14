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
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    // Gentle breathing scale on the logo tile.
    _scale = Tween<double>(begin: 0.97, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
          // Brand-red aura blurs for a soft, premium backdrop.
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: _AuraBlur(
              color: AppColors.primary,
              size: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: -MediaQuery.of(context).size.width * 0.2,
            child: _AuraBlur(
              color: AppColors.accentRedDeep,
              size: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.05,
            left: MediaQuery.of(context).size.width * 0.1,
            child: _AuraBlur(
              color: AppColors.primary,
              size: MediaQuery.of(context).size.width * 0.6,
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App-icon tile: the real Mass "M" mark on a brand-red tile,
                // gently breathing.
                ScaleTransition(
                  scale: _scale,
                  child: Transform.rotate(
                    angle: -4 * math.pi / 180,
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentRedDeep, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon/icon_m_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Mass Move',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
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
