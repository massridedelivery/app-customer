import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// A friendly "coming soon" dialog for features that aren't live yet
/// (e.g. food ordering, credit-card payment) or a service that isn't open in
/// the customer's area yet. Keeps the entry point visible so users know it's on
/// the way, without dead-ending them into an unfinished flow.
///
/// Pass [iconAsset] (a 3D service icon) to swap the default rocket for the
/// tapped section's own icon; [title] customises the headline (e.g.
/// "เร็วๆ นี้ในพื้นที่ของคุณ" for the out-of-area case).
Future<void> showComingSoonDialog(
  BuildContext context, {
  String title = 'เร็วๆ นี้',
  String message = 'กำลังจะเปิดให้บริการเร็วๆ นี้',
  String? iconAsset,
  String? locationLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: iconAsset != null
                  ? Image.asset(iconAsset, width: 48, height: 48)
                  : const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (locationLabel != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.foundationGrayscale100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        locationLabel,
                        style: AppTypography.body3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('รับทราบ', style: AppTypography.label2),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
