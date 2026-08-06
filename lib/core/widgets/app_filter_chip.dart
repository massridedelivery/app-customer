import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// App-wide selectable chip (pill). One consistent selected/unselected style
/// across screens: brand-red fill + border + bold text when selected, white
/// with a light-grey border otherwise.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const themeRed = AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.foundationRed100 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? themeRed : AppColors.foundationGrayscale300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label2.copyWith(
            color: selected ? themeRed : AppColors.semanticGrayNeutralFgHigh,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
