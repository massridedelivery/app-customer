import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/profile/presentation/widgets/tier_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "ระดับสมาชิก": every tier in the order the backend sends, each with its
/// own point range, bonus and benefits; the customer's is marked.
class LoyaltyTiersScreen extends ConsumerWidget {
  const LoyaltyTiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tiers = ref.watch(loyaltyTiersProvider);
    final mine = ref.watch(loyaltySummaryProvider).value?.tier?.code;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tierListTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: tiers.when(
        loading: () => const Center(child: MassLoadingM(size: 64)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(friendlyError(e), style: AppTypography.body3),
              TextButton(
                onPressed: () => ref.invalidate(loyaltyTiersProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(loyaltyTiersProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _TierCard(tier: list[i], current: list[i].code == mine),
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.current});

  final LoyaltyTier tier;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final c = tierColor(tier.color);
    final max = tier.maxPoints;
    final range = max == null
        ? l10n.tierRangeFrom(fmtPoints(tier.minPoints))
        : l10n.tierRange(fmtPoints(tier.minPoints), fmtPoints(max));
    final multiplier = tierMultiplierText(l10n, tier.earnMultiplier);
    final benefits = tier.benefitsFor(lang);
    return Container(
      key: Key('tierCard-${tier.code}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current ? c : const Color(0xFFE5E2E1),
          width: current ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TierBadge(
                name: tier.displayName(lang),
                color: tier.color,
                iconUrl: tier.iconUrl,
              ),
              const Spacer(),
              if (current)
                Text(
                  l10n.tierYours,
                  key: const Key('tierYours'),
                  style: AppTypography.caption4.copyWith(
                    color: Color.lerp(c, Colors.black, 0.3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(range, style: AppTypography.label2),
          if (multiplier != null)
            Text(
              multiplier,
              style: AppTypography.caption4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final b in benefits)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 6),
                      child: Icon(Icons.check_rounded, size: 16, color: c),
                    ),
                    Expanded(child: Text(b, style: AppTypography.body3)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
