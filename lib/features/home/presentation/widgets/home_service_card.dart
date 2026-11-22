import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// One card of the home service grid (เรียกรถ / สั่งอาหาร / เมสเซนเจอร์ /
/// จองล่วงหน้า): white, soft shadow, title + subtitle, an optional tinted
/// badge, and a 3D illustration in the bottom-right corner: the [iconAsset]
/// image, or a drawn [art] widget in its place.
class HomeServiceCard extends StatelessWidget {
  const HomeServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconAsset,
    this.art,
    this.badge,
    this.badgeColor,
    this.onTap,
    this.inkKey,
  });

  final String title;
  final String subtitle;
  final String? iconAsset;

  /// Drawn in the illustration's place when there is no [iconAsset].
  final Widget? art;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  /// Key on the tappable area, for tests.
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: inkKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption4.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? Colors.red).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.caption5.copyWith(
                          color: badgeColor ?? Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: 62,
                      height: 62,
                      fit: BoxFit.contain,
                    )
                  : SizedBox(width: 62, height: 62, child: art),
            ),
          ],
        ),
      ),
    );
  }
}
