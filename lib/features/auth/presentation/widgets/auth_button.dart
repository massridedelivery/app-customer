import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_typography.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              AppColors.foundationGreen500, // Default to Aber green or override
          disabledBackgroundColor: backgroundColor != null
              ? backgroundColor!.withValues(alpha: 0.6)
              : AppColors.foundationGreen500.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppTypography.label1.copyWith(
                  color: textColor ?? Colors.white,
                ),
              ),
      ),
    );
  }
}
