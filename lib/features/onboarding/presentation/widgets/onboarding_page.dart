import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:flutter/material.dart';

/// One onboarding page: a full-bleed [hero] with the home header's wave on its
/// bottom edge, then the page dots, title and description.
class OnboardingPageWidget extends StatelessWidget {
  final Widget hero;
  final String title;
  final String description;
  final int index;
  final int count;

  const OnboardingPageWidget({
    super.key,
    required this.hero,
    required this.title,
    required this.description,
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.52).clamp(
      300.0,
      520.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: ClipPath(clipper: HeroWaveClipper(), child: hero),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  count,
                  (i) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: i == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.primary
                          : const Color(0xFFD4D4DA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.heading2.copyWith(
                  fontSize: 26,
                  height: 1.3,
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: AppTypography.body1.copyWith(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
