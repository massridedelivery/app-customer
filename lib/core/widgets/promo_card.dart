import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Rounded promo/coupon card shell with a coloured left accent bar, shared by
/// the food and ride coupon lists. Feature-specific content goes in [child].
class PromoCardShell extends StatelessWidget {
  const PromoCardShell({
    super.key,
    required this.isSelected,
    required this.accentColor,
    required this.child,
  });

  final bool isSelected;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withAlpha(120)
              : const Color(0xFFEEEEEE),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withAlpha(20)
                : Colors.black.withAlpha(5),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 4,
              color: accentColor,
              constraints: const BoxConstraints(minHeight: 80),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 48×48 coupon icon tile. Greyed out when [active] is false.
class PromoIconTile extends StatelessWidget {
  const PromoIconTile({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: active ? AppColors.foundationRed100 : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.local_offer_outlined,
        color: active ? AppColors.primary : Colors.grey[400],
        size: 24,
      ),
    );
  }
}

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
    this.applyLabel = 'ใช้คูปอง',
    this.cancelLabel = 'ยกเลิก',
  });

  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final String applyLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
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
                  cancelLabel,
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
                  applyLabel,
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
