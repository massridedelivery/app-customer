import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// App-wide segmented-tab item: a solid brand-red pill with white text when
/// selected, plain grey text when not. Use for mutually-exclusive tab rows
/// (e.g. recent / recommended / saved).
class AppPillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppPillTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          // Fixed height + Center keeps the label vertically centred regardless
          // of Thai glyph metrics (tone marks reserve extra space above on iOS).
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppTypography.label1.copyWith(
                color: selected
                    ? AppColors.white
                    : AppColors.semanticGrayNeutralFgMidOnWhite,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
