import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/refetch_on_resume.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/features/profile/presentation/widgets/mass_points_card.dart';
import 'package:customer_app/features/profile/presentation/widgets/tier_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "คะแนนของฉัน" (design B): the same MASS POINTS card as the profile page
/// with แลกคะแนน / คูปองของฉัน / ชวนเพื่อน on a strip tucked under it, the
/// member tiers (design E), points about to expire, and the points history.
class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(loyaltySummaryProvider);
    ref.invalidate(pointsHistoryProvider);
    ref.invalidate(loyaltyTiersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(loyaltySummaryProvider);
    return RefetchOnResume(
      onResume: () => _refresh(ref),
      child: Scaffold(
        backgroundColor: AppColors.foundationGrayscale100,
        appBar: AppBar(
          title: Text(l10n.pointsTitle, style: AppTypography.heading4),
          backgroundColor: AppColors.foundationGrayscale100,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: summaryAsync.when(
          loading: () => const Center(child: MassLoadingM(size: 72)),
          error: (e, s) => _Retry(
            text: l10n.profileLoadFailed,
            onTap: () => _refresh(ref),
          ),
          data: (summary) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _refresh(ref);
              await ref.read(loyaltySummaryProvider.future);
            },
            child: _Body(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(pointsHistoryProvider);
    final entries = history.value?.items ?? const <PointsEntry>[];
    final hasMore = history.value?.hasMore ?? false;

    final header = <Widget>[
      if (!summary.pointsEnabled) ...[
        _Banner(
          key: const Key('pointsDisabledBanner'),
          icon: Icons.info_outline_rounded,
          text: l10n.pointsDisabled,
        ),
        const SizedBox(height: 12),
      ],
      // The card with its action strip tucked under it. Laid out bottom-up
      // so the card paints over the strip's top edge; the strip is pulled up
      // under the card by the same amount it is padded at the top.
      Column(
        verticalDirection: VerticalDirection.up,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(0, -_stripTuck),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _ActionStrip(
                actions: [
                  _StripAction(
                    key: const Key('pointsGoRewards'),
                    icon: Icons.redeem_rounded,
                    label: l10n.pointsActionRedeem,
                    onTap: () => context.push('/rewards'),
                  ),
                  _StripAction(
                    key: const Key('pointsGoVouchers'),
                    icon: Icons.confirmation_number_outlined,
                    label: l10n.pointsActionVouchers,
                    onTap: () => context.push('/vouchers'),
                  ),
                  _StripAction(
                    key: const Key('pointsGoReferral'),
                    icon: Icons.group_add_outlined,
                    label: l10n.pointsActionInvite,
                    onTap: () => context.push('/referral'),
                  ),
                ],
              ),
            ),
          ),
          MassPointsCard(
            summary: summary,
            name: ref.watch(profileControllerProvider).value?.editName ?? '',
          ),
        ],
      ),
      if (summary.tier != null) ...[
        TierLadder(
          tier: summary.tier!,
          tiers: ref.watch(loyaltyTiersProvider).value,
          onTap: () => context.push('/loyalty/tiers'),
        ),
      ],
      if (summary.expiringPoints > 0 && summary.expiringAt != null) ...[
        const SizedBox(height: 12),
        _Banner(
          key: const Key('pointsExpiring'),
          icon: Icons.schedule_rounded,
          text: l10n.pointsExpiring(
            fmtPoints(summary.expiringPoints),
            fmtThaiDate(context, summary.expiringAt!),
          ),
        ),
      ],
      if (summary.earnPer100Ride > 0) ...[
        const SizedBox(height: 16),
        Text(
          l10n.pointsEarnRule(
            fmtPoints(summary.earnPer100Ride),
            fmtBaht(summary.earnMinOrder),
          ),
          key: const Key('pointsEarnRule'),
          style: AppTypography.body3.copyWith(color: AppColors.textSecondary),
        ),
      ],
      const SizedBox(height: 24),
      Text(l10n.pointsHistory, style: AppTypography.heading5),
      const SizedBox(height: 8),
      if (history.isLoading && entries.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: MassLoadingM(size: 48)),
        )
      else if (history.hasError && entries.isEmpty)
        _Retry(
          text: l10n.profileLoadFailed,
          onTap: () => ref.invalidate(pointsHistoryProvider),
        )
      else if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              l10n.pointsHistoryEmpty,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400) {
          ref.read(pointsHistoryProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + MediaQuery.paddingOf(context).bottom),
        itemCount: header.length + entries.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i < header.length) return header[i];
          final j = i - header.length;
          if (j == entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: MassLoadingM(size: 40)),
            );
          }
          return _EntryRow(entry: entries[j]);
        },
      ),
    );
  }
}

/// A history row: Thai label by type, the description, date, ± points.
final _thai = RegExp(r'[\u0E00-\u0E7F]');

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final PointsEntry entry;

  static String label(AppLocalizations l10n, PointsEntry e) =>
      switch (e.type) {
        'EARN' when e.orderType == 'REFERRAL' => l10n.pointsTypeReferral,
        'EARN' => l10n.pointsTypeEarn,
        // Points spent on a voucher have no order; on a ride they do.
        'REDEEM' when e.orderType == null => l10n.pointsTypeVoucher,
        'REDEEM' => l10n.pointsTypeRedeem,
        'REFUND' => l10n.pointsTypeRefund,
        'EXPIRE' => l10n.pointsTypeExpire,
        'ADJUST' => l10n.pointsTypeAdjust,
        _ => e.type,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positive = entry.points > 0;
    final color = positive
        ? AppColors.semanticSuccessFgHigh
        : (entry.type == 'EXPIRE'
              ? AppColors.textSecondary
              : AppColors.semanticErrorFgHigh);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFF2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label(l10n, entry), style: AppTypography.label2),
                // Older rows carry an English description ("Earned from ride
                // order"); the Thai label above already says it, so only a
                // Thai description is shown.
                if (_thai.hasMatch(entry.description))
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (entry.createdAt != null)
                  Text(
                    fmtThaiDate(context, entry.createdAt!),
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '−'}${fmtPoints(entry.points.abs())}',
            style: AppTypography.heading5.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// How far the action strip slides up under the MASS POINTS card.
const double _stripTuck = 20;

/// White strip of shortcuts hanging under the MASS POINTS card; its top
/// padding sits under the card, so only its rounded bottom shows.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, _stripTuck + 8, 4, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFECEDF1),
                ),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _StripAction extends StatelessWidget {
  const _StripAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.label3,
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB45309)),
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

class _Retry extends StatelessWidget {
  const _Retry({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppTypography.body2),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTap,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
