import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/domain/models/referral_info.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "คูปองชวนเพื่อนครบเป้า": the referral coupon milestones as a progress
/// track — the next goal ("ชวนอีก 2 คน รับคูปอง ฿75"), each tier with its
/// coupon, reached ones marked earned with their code, and a link to the
/// customer's vouchers where those coupons are. Nothing when there are no
/// tiers.
class ReferralTiersTrack extends StatelessWidget {
  const ReferralTiersTrack({super.key, required this.info});

  final ReferralInfo info;

  @override
  Widget build(BuildContext context) {
    final tiers = info.tiers;
    if (tiers.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final next = info.nextTier;
    final earned = tiers.where((t) => t.reached).toList();
    final top = tiers.last.friends;
    final progress = top <= 0
        ? 0.0
        : (info.friendsCounted / top).clamp(0.0, 1.0).toDouble();

    return Column(
      key: const Key('referralTiers'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.referralTiersTitle, style: AppTypography.heading5),
        const SizedBox(height: 6),
        Text(
          next == null
              ? l10n.referralTiersAllDone
              : l10n.referralTiersNext(
                  fmtPoints(info.friendsToNextTier),
                  fmtBaht(next.amount),
                ),
          key: const Key('referralTiersNext'),
          style: AppTypography.label2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final t in tiers) Expanded(child: _TierStop(tier: t)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.referralTiersCounted(fmtPoints(info.friendsCounted)),
          style: AppTypography.caption4.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (earned.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final t in earned)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EarnedCoupon(tier: t),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('referralTiersVouchers'),
              onPressed: () => context.push('/vouchers'),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: Text(l10n.referralTiersSeeVouchers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.label2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One milestone under the bar: "฿75 · 5 คน", ticked once reached.
class _TierStop extends StatelessWidget {
  const _TierStop({required this.tier});

  final ReferralTier tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = tier.reached ? AppColors.primary : AppColors.textSecondary;
    return Column(
      key: Key('referralTier-${tier.friends}'),
      children: [
        Icon(
          tier.reached
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          '฿${fmtBaht(tier.amount)}',
          style: AppTypography.label2.copyWith(color: color),
        ),
        Text(
          l10n.referralTierFriends(fmtPoints(tier.friends)),
          style: AppTypography.caption4.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// A reached milestone's coupon: amount, "ได้แล้ว" and its code.
class _EarnedCoupon extends StatelessWidget {
  const _EarnedCoupon({required this.tier});

  final ReferralTier tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: Key('referralTierEarned-${tier.friends}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '฿${fmtBaht(tier.amount)} · ${l10n.referralTierEarned}',
                  style: AppTypography.label2,
                ),
                if (tier.voucherCode != null)
                  SelectableText(
                    tier.voucherCode!,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
