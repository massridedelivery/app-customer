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

  /// When true, the selected state is a solid brand-red fill with white text
  /// (instead of the default light-red tint with red text).
  final bool filled;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    const themeRed = AppColors.primary;
    final Color bg = selected
        ? (filled ? themeRed : AppColors.foundationRed100)
        : AppColors.white;
    final Color fg = selected
        ? (filled ? AppColors.white : themeRed)
        : AppColors.semanticGrayNeutralFgHigh;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? themeRed : AppColors.foundationGrayscale300,
            width: 1,
          ),
        ),
        // Fixed height + Center keeps the label vertically centred regardless of
        // Thai glyph metrics (tone marks reserve extra space above on iOS).
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppTypography.label2.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
