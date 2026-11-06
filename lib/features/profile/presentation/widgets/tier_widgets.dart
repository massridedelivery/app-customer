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

/// The tier section of คะแนนของฉัน (design E): every tier as a small card in
/// a horizontal row — the customer's marked "ระดับของคุณ", the next one with
/// "อีก N คะแนน" — then the progress bar and "อีก N คะแนนถึง {ระดับถัดไป}"
/// ("ระดับสูงสุดแล้ว" at the top). Until [tiers] loads (or when it fails) only
/// the customer's own tier is shown. Tapping it opens the full tier list.
class TierLadder extends StatelessWidget {
  const TierLadder({super.key, required this.tier, this.tiers, this.onTap});

  /// The customer's tier, from the summary (its multiplier and progress win).
  final LoyaltyTier tier;

  /// Every tier in the backend's order; null while loading or on error.
  final List<LoyaltyTier>? tiers;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = tierColor(tier.color);
    final all = tiers ?? const <LoyaltyTier>[];
    final list = all.any((t) => t.code == tier.code) ? all : [tier];
    final nextCode = tier.nextTier?.code;
    final progress = tier.progressPercent;
    final toNext = tier.pointsToNext;
    final lang = Localizations.localeOf(context).languageCode;
    final caption = tier.isTop
        ? l10n.tierTopReached
        : (toNext != null && tier.nextTier != null)
        ? l10n.tierToNext(fmtPoints(toNext), tier.nextTier!.displayName(lang))
        : null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('tierProgressCard'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Text(l10n.tierListTitle, style: AppTypography.label2),
                    const Spacer(),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                key: const Key('tierLadder'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      _LadderCard(
                        tier: list[i],
                        current: list[i].code == tier.code,
                        // The customer's own bonus comes from the summary.
                        multiplier: list[i].code == tier.code
                            ? tier.earnMultiplier
                            : list[i].earnMultiplier,
                        pointsLeft: list[i].code == nextCode ? toNext : null,
                      ),
                    ],
                  ],
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      key: const Key('tierProgress'),
                      value: progress / 100,
                      minHeight: 8,
                      color: c,
                      backgroundColor: c.withValues(alpha: 0.15),
                    ),
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

/// One tier in [TierLadder]'s row: an optional "ระดับของคุณ" / "อีก N คะแนน"
/// tag, a dot and the name in the tier's colour, its point range and bonus.
class _LadderCard extends StatelessWidget {
  const _LadderCard({
    required this.tier,
    required this.current,
    required this.multiplier,
    this.pointsLeft,
  });

  final LoyaltyTier tier;
  final bool current;
  final double multiplier;
  final int? pointsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final c = tierColor(tier.color);
    final dark = Color.lerp(c, Colors.black, 0.35)!;
    final max = tier.maxPoints;
    final range = max == null
        ? l10n.tierRangeFrom(fmtPoints(tier.minPoints))
        : l10n.tierRange(fmtPoints(tier.minPoints), fmtPoints(max));
    final bonus = tierMultiplierText(l10n, multiplier);
    final tag = current
        ? l10n.tierYours
        : pointsLeft != null
        ? l10n.tierPointsLeft(fmtPoints(pointsLeft!))
        : null;
    return Container(
      key: Key('tierLadder-${tier.code}'),
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: current ? c.withValues(alpha: 0.10) : const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current ? c : const Color(0xFFE5E2E1),
          width: current ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: current ? dark : AppColors.foundationRed100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: AppTypography.caption5.copyWith(
                  color: current ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tier.displayName(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label2.copyWith(
                    color: dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            range,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (bonus != null)
            Text(
              bonus,
              key: current ? const Key('tierMultiplier') : null,
              style: AppTypography.caption4.copyWith(
                color: dark,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
