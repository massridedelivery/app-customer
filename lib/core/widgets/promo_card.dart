import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Apply / cancel toggle shared by the promo cards: an outlined "use" button
/// that animates into a red "cancel" button once the promo [isSelected].
///
/// When [isEnabled] is false the apply button is shown disabled (greyed out).
class PromoApplyButton extends StatelessWidget {
  const PromoApplyButton({
    super.key,
    required this.isSelected,
    required this.onApply,
    required this.onCancel,
    this.isEnabled = true,
    this.applyLabel,
    this.cancelLabel,
  });

  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  /// Defaults to the localized "ใช้คูปอง" / "Use".
  final String? applyLabel;

  /// Defaults to the localized "ยกเลิก" / "Cancel".
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: SizedBox(
        key: ValueKey(isSelected),
        height: 32,
        child: isSelected
            ? ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[600],
                  elevation: 0,
                  side: BorderSide(color: Colors.red[100]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  cancelLabel ?? l10n.cancel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: isEnabled ? onApply : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: isEnabled ? AppColors.primary : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  applyLabel ?? l10n.promoUseCoupon,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? AppColors.primary : Colors.grey[400],
                  ),
                ),
              ),
      ),
    );
  }
}
