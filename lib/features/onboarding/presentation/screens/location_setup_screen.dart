import 'dart:math' as math;

import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LocationSetupScreen extends ConsumerWidget {
  const LocationSetupScreen({super.key});

  Future<void> _handleCompleteOnboarding(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();

    if (!context.mounted) return;

    // Navigate to auth screen
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Illustration Placeholder
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: AppColors.primary,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -6 * math.pi / 180,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.deepBlue,
                                AppColors.darkestBlue,
                              ],
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
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Content
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ยินดีที่ได้รู้จัก!',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เลือกตำแหน่งของคุณเพื่อเริ่มค้นหา\nบริการรอบตัวคุณ',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Use Current Location Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _handleCompleteOnboarding(context, ref),
                        icon: AppIcons.asset(
                          AppAssets.icLocationFill,
                          width: 20,
                          height: 20,
                          color: AppColors.foundationGreen500,
                        ),
                        label: Text(
                          'ใช้ตำแหน่งปัจจุบัน',
                          style: AppTypography.label1.copyWith(
                            color: AppColors.foundationGreen500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.foundationGreen500,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Select Map Button (Text style)
                    TextButton(
                      onPressed: () => _handleCompleteOnboarding(context, ref),
                      child: Text(
                        'เลือกตำแหน่งด้วยตัวเอง',
                        style: AppTypography.label1.copyWith(
                          color: AppColors.semanticErrorFgHigh,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.semanticErrorFgHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
