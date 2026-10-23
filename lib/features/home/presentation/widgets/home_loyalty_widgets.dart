import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/presentation/screens/referral_screen.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home cards for the referral programme: "มีโค้ดจากเพื่อนไหม?" for a new
/// customer who may still use one, and "ชวนเพื่อน รับ N คะแนน" → ชวนเพื่อน.
class HomeReferralCards extends ConsumerWidget {
  const HomeReferralCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    if (!signedIn) return const SizedBox.shrink();
    final info = ref.watch(referralInfoProvider).value;
    if (info == null || !info.enabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final canStillApply =
        info.canApplyCode &&
        !info.wasReferred &&
        (info.applyBefore == null ||
            info.applyBefore!.isAfter(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          if (canStillApply) ...[
            _Card(
              key: const Key('homeHaveFriendCode'),
              icon: Icons.card_giftcard_rounded,
              title: l10n.referralHaveFriendCode,
              subtitle: l10n.referralHaveFriendCodeSub(
                fmtBaht(info.friendRewardValue),
              ),
              onTap: () => context.push('/ride-landing'),
            ),
            const SizedBox(height: 10),
          ],
          if (info.referrerRewardPoints > 0)
            _Card(
              key: const Key('homeReferralBanner'),
              icon: Icons.group_add_rounded,
              title: l10n.homeReferralBanner(
                fmtPoints(info.referrerRewardPoints),
              ),
              onTap: () => context.push('/referral'),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDF1F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.label1),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
