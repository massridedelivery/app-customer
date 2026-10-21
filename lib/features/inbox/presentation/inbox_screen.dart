import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/layout.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/widgets/login_required_view.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:customer_app/features/inbox/presentation/inbox_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "กล่องข้อความ" tab: marketing campaigns (also sent as pushes), newest
/// first, unread ones tinted with a red dot. Tapping one marks it read and
/// opens the screen the campaign points at.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _unreadOnly = false;

  void _open(InboxItem item) {
    ref.read(inboxControllerProvider.notifier).markRead(item);
    final link = item.deeplink;
    if (link != null) context.push(link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    if (!signedIn) {
      return const Scaffold(body: SafeArea(child: LoginRequiredView()));
    }
    final inbox = ref.watch(inboxControllerProvider);
    final unread = ref.watch(inboxUnreadProvider);
    final bottomPad =
        8 + kFloatingNavReserve + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l10n.navInbox,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.inboxAll,
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: unread > 0
                        ? '${l10n.inboxUnread} $unread'
                        : l10n.inboxUnread,
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                  const Spacer(),
                  if (unread > 0)
                    TextButton(
                      key: const Key('inboxMarkAllRead'),
                      onPressed: () => ref
                          .read(inboxControllerProvider.notifier)
                          .markAllRead(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(l10n.inboxMarkAllRead,
                          style: AppTypography.label2),
                    ),
                ],
              ),
            ),
            Expanded(
              child: inbox.when(
                loading: () => const Center(child: MassLoadingM(size: 72)),
                error: (_, _) => _Message(
                  icon: Icons.cloud_off_outlined,
                  title: l10n.inboxLoadFailed,
                  onTap: () =>
                      ref.read(inboxControllerProvider.notifier).refresh(),
                ),
                data: (s) {
                  final items = _unreadOnly
                      ? s.items.where((i) => !i.isRead).toList()
                      : s.items;
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(inboxControllerProvider.notifier).refresh(),
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              _unreadOnly && s.items.isNotEmpty
                                  ? _Message(
                                      icon: Icons.mark_email_read_outlined,
                                      title: l10n.inboxAllCaughtUp,
                                    )
                                  : _Message(
                                      icon: Icons.notifications_none_rounded,
                                      title: l10n.inboxEmpty,
                                      subtitle: l10n.inboxEmptySub,
                                    ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(bottom: bottomPad),
                            itemCount: items.length,
                            itemBuilder: (context, i) => _InboxTile(
                              item: items[i],
                              onTap: () => _open(items[i]),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFF2F2F5),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: AppTypography.label3.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  /// Icon + colour by the campaign's target screen.
  static (IconData, Color) _look(String screen) => switch (screen) {
    'promo' => (Icons.local_offer_outlined, AppColors.primary),
    'referral' => (Icons.card_giftcard_rounded, const Color(0xFFE08A00)),
    'ride_landing' => (Icons.directions_car_outlined, const Color(0xFF1D4ED8)),
    'messenger_booking' => (Icons.inventory_2_outlined, const Color(0xFF047857)),
    'loyalty' => (Icons.star_border_rounded, const Color(0xFFB45309)),
    'restaurant' ||
    'category' ||
    'food_delivery' => (Icons.restaurant_rounded, const Color(0xFFB45309)),
    _ => (Icons.campaign_outlined, AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final (icon, color) = _look(item.screen);
    return Material(
      color: unread ? const Color(0xFFFDF1F3) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEFEFF2))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: unread ? color : const Color(0xFFEFEFF2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: unread ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.label2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            key: const Key('inboxUnreadDot'),
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      AppDates.of(context).relative(item.createdAt),
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.label1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
