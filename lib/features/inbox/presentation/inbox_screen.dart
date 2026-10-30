import 'package:app_settings/app_settings.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/layout.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/widgets/login_required_view.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:customer_app/features/inbox/presentation/inbox_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/core/widgets/points_coin.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "กล่องข้อความ" tab: marketing campaigns (also sent as pushes), newest
/// first, unread ones tinted with a red dot. Tapping one marks it read and
/// opens the screen the campaign points at; swiping one left deletes it.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _unreadOnly = false;

  /// Times each message came back after a failed delete: part of its row's
  /// key, so a restored row is a new Dismissible, not the dismissed one.
  final _restores = <String, int>{};

  void _open(InboxItem item) {
    ref.read(inboxControllerProvider.notifier).markRead(item);
    final link = item.deeplink;
    if (link != null) context.push(link);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          // Above the floating tab bar.
          margin: EdgeInsets.fromLTRB(16, 0, 16, kFloatingNavReserve + 8),
        ),
      );
  }

  Future<void> _delete(InboxItem item) async {
    final failed = AppLocalizations.of(context)!.inboxActionFailed;
    try {
      await ref.read(inboxControllerProvider.notifier).delete(item);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _restores.update(item.id, (n) => n + 1, ifAbsent: () => 1),
      );
      _toast(failed);
    }
  }

  Future<void> _markAllRead() async {
    final failed = AppLocalizations.of(context)!.inboxActionFailed;
    try {
      await ref.read(inboxControllerProvider.notifier).markAllRead();
    } catch (_) {
      if (mounted) _toast(failed);
    }
  }

  /// Deleting is permanent, so it always asks first.
  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('inboxDeleteAllConfirm'),
        title: Text(l10n.inboxDeleteAllTitle, style: AppTypography.heading4),
        content: Text(
          l10n.inboxDeleteAllBody,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('inboxDeleteAllYes'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.inboxDeleteAll),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(inboxControllerProvider.notifier).deleteAll();
    } catch (_) {
      if (mounted) _toast(l10n.inboxActionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    if (!signedIn) {
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(body: SafeArea(child: LoginRequiredView())),
      );
    }
    final inbox = ref.watch(inboxControllerProvider);
    final unread = ref.watch(inboxUnreadProvider);
    final bottomPad =
        8 + kFloatingNavReserve + MediaQuery.of(context).viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.navInbox,
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (inbox.value?.items.isNotEmpty ?? false)
                      PopupMenuButton<void>(
                        key: const Key('inboxMenu'),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textSecondary,
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem<void>(
                            key: const Key('inboxDeleteAll'),
                            onTap: _confirmDeleteAll,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.inboxDeleteAll,
                                  style: AppTypography.label2.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
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
                        onPressed: _markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(
                          l10n.inboxMarkAllRead,
                          style: AppTypography.label2,
                        ),
                      ),
                  ],
                ),
              ),
              if (ref.watch(pushPermissionDeniedProvider)) const _PushOffHint(),
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
                          : NotificationListener<ScrollNotification>(
                              // Infinite scroll: fetch the next page near the end.
                              onNotification: (n) {
                                if (n.metrics.extentAfter < 400) {
                                  ref
                                      .read(inboxControllerProvider.notifier)
                                      .loadMore();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(bottom: bottomPad),
                                itemCount: items.length + (s.hasMore ? 1 : 0),
                                itemBuilder: (context, i) => i == items.length
                                    ? const Padding(
                                        key: Key('inboxLoadingMore'),
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: MassLoadingM(size: 40),
                                        ),
                                      )
                                    : Dismissible(
                                        key: ValueKey(
                                          '${items[i].id}/${_restores[items[i].id] ?? 0}',
                                        ),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (_) => _delete(items[i]),
                                        background: const _DeleteBackground(),
                                        child: _InboxTile(
                                          item: items[i],
                                          onTap: () => _open(items[i]),
                                        ),
                                      ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
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
    'messenger_booking' => (
      Icons.inventory_2_outlined,
      const Color(0xFF047857),
    ),
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
              if (item.screen == 'loyalty')
                const PointsCoin(size: 40)
              else
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
                                  : FontWeight.w500,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      // In Thailand time, whatever the device timezone.
                      AppDates.of(context).relative(
                        AppDates.bangkok(item.createdAt),
                        now: AppDates.bangkok(DateTime.now()),
                      ),
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

/// What shows under a row as it's swiped away.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.inboxDelete,
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
        ],
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

/// Notifications are turned off for the app: what they'd bring, and the way
/// back on.
class _PushOffHint extends StatelessWidget {
  const _PushOffHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('inboxPushOffHint'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inboxPushOffTitle,
                  style: AppTypography.label2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.inboxPushOffBody,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            // The app's own Settings page (its Notifications row is there);
            // the notification-settings link landed on the Settings root.
            onPressed: () => AppSettings.openAppSettings(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(l10n.inboxPushOffAction, style: AppTypography.label2),
          ),
        ],
      ),
    );
  }
}
