import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The tier's own colour (admin hex), or the brand red.
Color tierColor(int? argb) => argb == null ? AppColors.primary : Color(argb);

/// "ได้คะแนน ×1.5" — only when the multiplier isn't 1.
String? tierMultiplierText(AppLocalizations l10n, double multiplier) {
  if ((multiplier - 1).abs() < 0.001) return null;
  final x = multiplier == multiplier.roundToDouble()
      ? multiplier.toStringAsFixed(0)
      : multiplier.toStringAsFixed(1);
  return l10n.tierEarnMultiplier(x);
}

/// Pill with the tier's icon (or a dot in its colour) and name.
class TierBadge extends StatelessWidget {
  const TierBadge({
    super.key,
    required this.name,
    this.color,
    this.iconUrl,
    this.onDark = false,
  });

  final String name;

  /// ARGB from the admin's hex.
  final int? color;
  final String? iconUrl;

  /// On the red points card: white pill.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = tierColor(color);
    final icon = iconUrl;
    return Container(
      key: const Key('tierBadge'),
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: onDark ? null : Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Image.network(
              icon,
              width: 16,
              height: 16,
              errorBuilder: (_, _, _) => _Dot(color: c),
            )
          else
            _Dot(color: c),
          const SizedBox(width: 5),
          Text(
            name,
            style: AppTypography.caption4.copyWith(
              fontWeight: FontWeight.w700,
              color: onDark ? c : Color.lerp(c, Colors.black, 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('tierDot'),
    width: 10,
    height: 10,
    margin: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// The customer's tier on "คะแนนของฉัน": badge, ×multiplier, progress bar
/// with "อีก N คะแนนถึง {ระดับถัดไป}" (full bar and "ระดับสูงสุดแล้ว" at the
/// top), and a way to the tier list.
class TierProgressCard extends StatelessWidget {
  const TierProgressCard({super.key, required this.tier, this.onTap});

  final LoyaltyTier tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final c = tierColor(tier.color);
    final multiplier = tierMultiplierText(l10n, tier.earnMultiplier);
    final next = tier.nextTier;
    final progress = tier.progressPercent;
    final toNext = tier.pointsToNext;
    final caption = tier.isTop
        ? l10n.tierTopReached
        : (toNext != null && next != null)
        ? l10n.tierToNext(fmtPoints(toNext), next.displayName(lang))
        : null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('tierProgressCard'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l10n.tierListTitle, style: AppTypography.label2),
                  const SizedBox(width: 8),
                  TierBadge(
                    name: tier.displayName(lang),
                    color: tier.color,
                    iconUrl: tier.iconUrl,
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              if (multiplier != null) ...[
                const SizedBox(height: 6),
                Text(
                  multiplier,
                  key: const Key('tierMultiplier'),
                  style: AppTypography.caption4.copyWith(
                    color: Color.lerp(c, Colors.black, 0.3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: const Key('tierProgress'),
                    value: progress / 100,
                    minHeight: 8,
                    color: c,
                    backgroundColor: c.withValues(alpha: 0.15),
                  ),
                ),
              ],
              if (caption != null) ...[
                const SizedBox(height: 6),
                Text(
                  caption,
                  key: const Key('tierCaption'),
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
