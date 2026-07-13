import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header / Hero ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => const _ProfileHeaderShimmer(),
              error: (e, s) =>
                  _ProfileHeader(name: 'Error', phone: '', loyalty: null),
              data: (p) => _ProfileHeader(
                name: p.editName,
                phone: p.phone,
                loyalty: null,
              ),
            ),
          ),

          // ── Quick Actions Grid ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _QuickActionsGrid(l10n: l10n),
            ),
          ),

          // ── Settings & Support ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: l10n.accountSettings),
                  const SizedBox(height: 8),
                  _MenuCard(
                    items: [
                      _MenuTile(
                        icon: Icons.person_outline_rounded,
                        title: l10n.personalInfo,
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _MenuTile(
                        icon: Icons.language_rounded,
                        title: l10n.changeLanguage,
                        trailing: Text(
                          ref.watch(localeControllerProvider).languageCode ==
                                  'th'
                              ? 'ไทย'
                              : 'EN',
                          style: AppTypography.body3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onTap: () => _showLangSelector(context, ref, l10n),
                      ),
                      _MenuTile(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notifications,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.safetyPrivacy),
                  const SizedBox(height: 8),
                  _MenuCard(
                    items: [
                      _MenuTile(
                        icon: Icons.sos_rounded,
                        title: l10n.sosEmergency,
                        iconColor: AppColors.error,
                        onTap: () => context.push('/sos'),
                      ),
                      _MenuTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPdpa,
                        onTap: () => context.push('/privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.logout,
                        style: AppTypography.label2.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLangSelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final current = ref.read(localeControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.foundationGrayscale200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.changeLanguage, style: AppTypography.heading5),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('ภาษาไทย'),
            trailing: current.languageCode == 'th'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(const Locale('th'));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: current.languageCode == 'en'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Header Component ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final Map<String, dynamic>? loyalty;

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.loyalty,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 80, 22, 22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.foundationGrayscale100,
                      border: Border.all(
                        color: AppColors.foundationGrayscale200,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTypography.heading4.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone.isNotEmpty ? phone : l10n.member,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.navigate_next_rounded,
                      color: AppColors.foundationGrayscale400,
                      size: 28,
                    ),
                  ),
                ],
              ),
              if (loyalty != null) ...[
                if (false) ...[
                  const SizedBox(height: 24),
                  const Divider(
                    color: AppColors.foundationGrayscale100,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  _LoyaltySummary(loyalty: loyalty!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltySummary extends StatelessWidget {
  final Map<String, dynamic> loyalty;

  const _LoyaltySummary({required this.loyalty});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = loyalty['points_balance'] ?? 0;
    final tier = loyalty['tier'] ?? l10n.member;
    final tierIcon = loyalty['tier_icon'] ?? '💎';

    return GestureDetector(
      onTap: () => context.push('/loyalty'),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: l10n.points,
            value: '$points',
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.foundationGrayscale100,
          ),
          _StatItem(
            label: l10n.member,
            value: '$tierIcon $tier',
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.foundationGrayscale100,
          ),
          _StatItem(
            label: l10n.cashback,
            value:
                '${((loyalty['cashback_rate'] ?? 0.0) * 100).toStringAsFixed(0)}%',
            color: AppColors.accentRedVibrant,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.heading5.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.support1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderShimmer extends StatelessWidget {
  const _ProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) => Container(
    height: 240,
    color: Colors.white,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final AppLocalizations l10n;

  const _QuickActionsGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.history_rounded,
        label: l10n.history,
        route: '/main?tab=1',
        color: Color(0xFFF3FBF5),
      ),
      _ActionItem(
        icon: Icons.restaurant_rounded,
        label: l10n.orders,
        route: '/food-delivery',
        color: Color(0xFFFFF7ED),
      ),
      _ActionItem(
        icon: Icons.location_on_outlined,
        label: l10n.addresses,
        route: '/saved-places',
        color: Color(0xFFEFF6FF),
      ),
      _ActionItem(
        icon: Icons.local_offer_outlined,
        label: l10n.promos,
        route: '/promos',
        color: Color(0xFFFEF2F2),
      ),
      _ActionItem(
        icon: Icons.wallet_rounded,
        label: l10n.wallet,
        route: '#',
        color: Color(0xFFF5F3FF),
      ),
      _ActionItem(
        icon: Icons.headset_mic_outlined,
        label: l10n.support,
        route: '#',
        color: Color(0xFFF0FDFA),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: actions.length,
        itemBuilder: (ctx, i) => actions[i],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (route == '#') return;
        if (route.startsWith('/main')) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.body3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Menu Components ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.label2.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> items;

  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Column(children: items),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: AppTypography.body2.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.foundationGrayscale300,
          ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
