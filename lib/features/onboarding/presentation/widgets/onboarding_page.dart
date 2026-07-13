import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';

class OnboardingPageWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for the illustration
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFFF0F4F8,
              ), // Light grayish-blue for background circle
            ),
            child: icon,
          ),
          const SizedBox(height: 60),
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: AppColors.semanticGrayNeutralFgHigh,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: AppTypography.caption4.copyWith(
              color: AppColors.semanticGrayNeutralFgHigh,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
