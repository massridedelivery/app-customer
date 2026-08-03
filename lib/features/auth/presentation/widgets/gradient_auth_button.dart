import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// The brand-red gradient CTA used across the auth flow (register, forgot
/// password, reset). A real [Material]/[InkWell] button — ripple + button
/// semantics — replacing the bare `GestureDetector`+`Container` that each auth
/// screen had copy-pasted. Pass `onPressed: null` (or `isLoading: true`) to show
/// the disabled state.
class GradientAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GradientAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Neutral slate for the disabled state, matching the rest of the auth flow.
  static const Color _disabledBg = Color(0xFFE2E8F0);
  static const Color _disabledText = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPressed : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondaryRed],
                    )
                  : null,
              color: enabled ? null : _disabledBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTypography.label2.copyWith(
                        color: enabled ? Colors.white : _disabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
