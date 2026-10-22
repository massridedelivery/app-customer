import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/widgets/refetch_on_resume.dart';
import 'package:customer_app/features/profile/domain/models/loyalty_models.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "คะแนนของฉัน": balance and its baht value, points about to expire,
/// shortcuts to แลกคะแนน / คูปองของฉัน / ชวนเพื่อน, and the points history.
class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(loyaltySummaryProvider);
    ref.invalidate(pointsHistoryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(loyaltySummaryProvider);
    return RefetchOnResume(
      onResume: () => _refresh(ref),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.pointsTitle, style: AppTypography.heading4),
          backgroundColor: AppColors.background,
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
      _BalanceCard(summary: summary),
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
      const SizedBox(height: 16),
      Row(
        children: [
          _Shortcut(
            key: const Key('pointsGoRewards'),
            icon: Icons.redeem_rounded,
            label: l10n.pointsActionRedeem,
            onTap: () => context.push('/rewards'),
          ),
          const SizedBox(width: 10),
          _Shortcut(
            key: const Key('pointsGoVouchers'),
            icon: Icons.confirmation_number_outlined,
            label: l10n.pointsActionVouchers,
            onTap: () => context.push('/vouchers'),
          ),
          const SizedBox(width: 10),
          _Shortcut(
            key: const Key('pointsGoReferral'),
            icon: Icons.group_add_outlined,
            label: l10n.pointsActionInvite,
            onTap: () => context.push('/referral'),
          ),
        ],
      ),
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accentRedDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                fmtPoints(summary.totalPoints),
                key: const Key('pointsBalance'),
                style: AppTypography.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pointsUnit,
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pointsWorth(fmtBaht(summary.balanceBaht)),
            style: AppTypography.body2.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// A history row: Thai label by type, the description, date, ± points.
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
                if (entry.description.isNotEmpty)
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

class _Shortcut extends StatelessWidget {
  const _Shortcut({
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
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.label3,
                ),
              ],
            ),
          ),
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
