import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/refetch_on_resume.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/profile/presentation/widgets/redeem_sheet.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The redeem button's state for [reward], from the backend's `reason`:
/// a label, and whether it can be tapped.
(String, bool) rewardButton(
  BuildContext context,
  Reward reward,
  int balance, {
  required bool pointsEnabled,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (!pointsEnabled || reward.reason == 'POINTS_DISABLED') {
    return (l10n.rewardsRedeem, false);
  }
  if (reward.canRedeem && reward.reason == null) {
    return (l10n.rewardsRedeem, true);
  }
  return switch (reward.reason) {
    'INSUFFICIENT_POINTS' => (
      l10n.rewardsShort(
        fmtPoints((reward.pointsCost - balance).clamp(1, 1 << 30)),
      ),
      false,
    ),
    'OUT_OF_STOCK' => (l10n.rewardsOutOfStock, false),
    'LIMIT_REACHED' => (l10n.rewardsLimitReached, false),
    'NOT_STARTED' when reward.startsAt != null => (
      l10n.rewardsNotStarted(fmtThaiDate(context, reward.startsAt!)),
      false,
    ),
    'NOT_STARTED' => (l10n.rewardsComingSoon, false),
    'ENDED' => (l10n.rewardsEnded, false),
    _ => (l10n.rewardsRedeem, false),
  };
}

/// "แลกคะแนน": the rewards grid with this customer's balance on top.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rewards = ref.watch(rewardsProvider);
    return RefetchOnResume(
      onResume: () => ref.invalidate(rewardsProvider),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.rewardsTitle, style: AppTypography.heading4),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: rewards.when(
          loading: () => const Center(child: MassLoadingM(size: 72)),
          error: (e, s) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(rewardsProvider),
              child: Text('${l10n.profileLoadFailed} · ${l10n.retry}'),
            ),
          ),
          data: (list) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(rewardsProvider);
              await ref.read(rewardsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        l10n.rewardsYouHave(fmtPoints(list.pointsBalance)),
                        key: const Key('rewardsBalance'),
                        style: AppTypography.heading4,
                      ),
                      if (!list.pointsEnabled) ...[
                        const SizedBox(height: 12),
                        _DisabledBanner(text: l10n.pointsDisabled),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (list.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.rewardsEmpty,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                      itemCount: list.items.length,
                      itemBuilder: (context, i) => _RewardCard(
                        reward: list.items[i],
                        balance: list.pointsBalance,
                        pointsEnabled: list.pointsEnabled,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends ConsumerWidget {
  const _RewardCard({
    required this.reward,
    required this.balance,
    required this.pointsEnabled,
  });

  final Reward reward;
  final int balance;
  final bool pointsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final (label, enabled) = rewardButton(
      context,
      reward,
      balance,
      pointsEnabled: pointsEnabled,
    );
    return Material(
      key: Key('reward-${reward.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/rewards/detail',
          extra: (reward, balance, pointsEnabled),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: RewardImage(url: reward.imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reward.discountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.rewardsCost(fmtPoints(reward.pointsCost)),
                      style: AppTypography.label2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (reward.stockLeft != null && reward.stockLeft! <= 10)
                      Text(
                        l10n.rewardsStockLeft(fmtPoints(reward.stockLeft!)),
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.semanticErrorFgHigh,
                        ),
                      ),
                    if (reward.endsAt != null)
                      Text(
                        l10n.rewardsEndsAt(
                          fmtThaiDate(context, reward.endsAt!),
                        ),
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: FilledButton(
                        key: Key('rewardRedeem-${reward.id}'),
                        onPressed: enabled
                            ? () => confirmRedeem(
                                context,
                                ref,
                                reward: reward,
                                balance: balance,
                              )
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.semanticDisabledBgLow,
                          disabledForegroundColor:
                              AppColors.semanticDisabledFgOnGray,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: FittedBox(
                          child: Text(label, style: AppTypography.label3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reward's picture, or a gift placeholder when it has none / fails.
class RewardImage extends StatelessWidget {
  const RewardImage({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFFFDF1F3),
      child: Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _DisabledBanner extends StatelessWidget {
  const _DisabledBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('rewardsDisabledBanner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.label3.copyWith(
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reward in full: big picture, description, terms, redeem button.
class RewardDetailScreen extends ConsumerWidget {
  const RewardDetailScreen({
    super.key,
    required this.reward,
    required this.balance,
    required this.pointsEnabled,
  });

  final Reward reward;
  final int balance;
  final bool pointsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final (label, enabled) = rewardButton(
      context,
      reward,
      balance,
      pointsEnabled: pointsEnabled,
    );
    final terms = reward.terms
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: RewardImage(url: reward.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTypography.heading4),
                const SizedBox(height: 4),
                Text(
                  reward.discountText,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rewardsCost(fmtPoints(reward.pointsCost)),
                  style: AppTypography.heading5.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (reward.endsAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.rewardsEndsAt(fmtThaiDate(context, reward.endsAt!)),
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (reward.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(reward.description, style: AppTypography.body2),
                ],
                if (terms.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(l10n.rewardsTerms, style: AppTypography.heading5),
                  const SizedBox(height: 6),
                  for (final line in terms)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(
                            child: Text(line, style: AppTypography.body3),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            key: const Key('rewardDetailRedeem'),
            onPressed: enabled
                ? () => confirmRedeem(
                    context,
                    ref,
                    reward: reward,
                    balance: balance,
                  )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.semanticDisabledBgLow,
              disabledForegroundColor: AppColors.semanticDisabledFgOnGray,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(label, style: AppTypography.label1),
          ),
        ),
      ),
    );
  }
}
