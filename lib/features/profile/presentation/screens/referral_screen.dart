import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/referral_remote_data_source.dart';
import 'package:customer_app/features/profile/data/welcome_promo_store.dart';
import 'package:customer_app/features/profile/domain/models/referral_info.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The user's referral programme state. autoDispose: every visit reads fresh
/// stats (and the backend creates the user's code on this GET).
final referralInfoProvider = FutureProvider.autoDispose<ReferralInfo>((
  ref,
) async {
  final json = await ref.watch(referralRemoteDataSourceProvider).getInfo();
  final info = ReferralInfo.fromJson(json);
  // A referred newcomer who hasn't ordered yet: keep their welcome code ready
  // to pre-fill on the first ride / parcel.
  if (info.welcomePromoPending) {
    await ref.read(welcomePromoStoreProvider).save(info.referredByWelcomeCode!);
  }
  return info;
});

/// "ชวนเพื่อน": share your code, see how many friends used it and what each
/// earned you. Friends type the code in the promo box on their first ride.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  // Referrer points land a few seconds after a friend's first job ends: if the
  // page was left open in the background, read fresh stats on return.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(referralInfoProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(referralInfoProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileReferralTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, s) => Center(
          child: Text(l10n.profileLoadFailed, style: AppTypography.body2),
        ),
        data: (info) => !info.enabled
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.referralNotOpen,
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(referralInfoProvider),
                child: _ReferralBody(info: info),
              ),
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.info});

  final ReferralInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendValue = fmtBaht(info.friendRewardValue);
    final code = info.code ?? '';
    final shareText =
        info.shareMessage ?? l10n.referralShareText(code, friendValue);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
      children: [
        if (info.referredByCode != null) ...[
          Text(
            l10n.referralReferredBy(info.referredByCode!),
            key: const Key('referralReferredBy'),
            textAlign: TextAlign.center,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (info.welcomePromoPending) ...[
          _Notice(
            key: const Key('referralWelcomeReminder'),
            icon: Icons.card_giftcard_rounded,
            text: l10n.referralUseWelcomeCode(
              info.referredByWelcomeCode!,
              fmtBaht(info.referredByWelcomeValue),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Hero: what each side gets, straight from the backend.
        Container(
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
            children: [
              const Icon(
                Icons.group_add_rounded,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.referralHeadlineV2(
                  friendValue,
                  fmtPoints(info.referrerRewardPoints),
                ),
                key: const Key('referralHeadline'),
                style: AppTypography.heading4.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Code + copy + share.
        _Card(
          child: Column(
            children: [
              Text(
                l10n.profileReferralYourCode,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                code,
                key: const Key('referralCode'),
                style: AppTypography.heading1.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
              if (info.codeFull) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.referralCodeFull,
                  key: const Key('referralCodeFull'),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticErrorFgHigh,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('referralCopy'),
                      onPressed: code.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.profileReferralCodeCopied,
                                    ),
                                  ),
                                );
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.profileReferralCopy),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTypography.label2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('referralShare'),
                      onPressed: code.isEmpty
                          ? null
                          : () => SharePlus.instance.share(
                              ShareParams(text: shareText),
                            ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(l10n.profileReferralShare),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTypography.label2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // How it works: share → friend's first ride → your points.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.referralStepsTitle, style: AppTypography.heading5),
              const SizedBox(height: 12),
              _Step(n: 1, text: l10n.referralStep1),
              _Step(n: 2, text: l10n.referralStep2),
              _Step(n: 3, text: l10n.referralStep3, last: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Results.
        Row(
          children: [
            _Stat(
              label: l10n.referralStatInvited,
              value: fmtPoints(info.stats.totalReferrals),
            ),
            const SizedBox(width: 10),
            _Stat(
              label: l10n.referralStatCompleted,
              value: fmtPoints(info.stats.completedCount),
            ),
            const SizedBox(width: 10),
            _Stat(
              label: l10n.referralStatPoints,
              value: fmtPoints(info.stats.totalRewardPoints),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.referralStatsLine(
            fmtPoints(info.stats.totalReferrals),
            fmtPoints(info.stats.completedCount),
            fmtPoints(info.stats.totalRewardPoints),
          ),
          key: const Key('referralStatsLine'),
          textAlign: TextAlign.center,
          style: AppTypography.caption4.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (info.friends.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.referralFriendsTitle, style: AppTypography.heading5),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < info.friends.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  _FriendRow(friend: info.friends[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One numbered step of "how it works".
class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text, this.last = false});

  final int n;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF1F3),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: AppTypography.label2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.body2)),
        ],
      ),
    );
  }
}

/// A friend on the list: masked name and where their referral stands.
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend});

  final ReferralFriend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (IconData icon, Color color, String status) = switch (friend.status) {
      'REWARDED' => (
        Icons.check_circle_rounded,
        AppColors.semanticSuccessFgHigh,
        l10n.referralFriendRewarded(fmtPoints(friend.points)),
      ),
      'CANCELLED' => (
        Icons.cancel_outlined,
        AppColors.textSecondary,
        l10n.referralFriendCancelled,
      ),
      _ => (
        Icons.hourglass_top_rounded,
        const Color(0xFFE08A00),
        l10n.referralFriendPending,
      ),
    };
    final date = friend.status == 'REWARDED'
        ? friend.rewardedAt
        : friend.createdAt;
    return Row(
      key: Key('referralFriend-${friend.status}'),
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.name,
                style: AppTypography.label2.copyWith(
                  color: friend.status == 'CANCELLED'
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              if (date != null)
                Text(
                  fmtThaiDate(context, date),
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Text(status, style: AppTypography.label3.copyWith(color: color)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.semanticSuccessBgLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.semanticSuccessFgHigh),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticSuccessFgHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.heading3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
