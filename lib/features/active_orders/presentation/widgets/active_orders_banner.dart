import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Resume live activity" strip on the home surface (SCRUM-45 §6).
/// Shows the newest active order across verticals (ride + food + messenger)
/// with a +N badge when more are running.
class ActiveOrdersBanner extends ConsumerWidget {
  const ActiveOrdersBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeOrdersControllerProvider);

    return activeOrdersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        // Newest first per spec — surface the most recent one
        final ActiveOrderItem order = orders.first;
        final l10n = AppLocalizations.of(context)!;
        final (:title, :statusText, :icon) = _describe(l10n, order);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFEF4F5), // soft red bg
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openOrder(context, orders, order),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Vertical Status Indicator with Pulse Animation Effect
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Center details — service name on top, live status below.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: AppTypography.label1.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (orders.length > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '+${orders.length - 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: AppTypography.caption5.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.homeViewStatus,
                            style: AppTypography.caption4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ({String title, String statusText, IconData icon}) _describe(
    AppLocalizations l10n,
    ActiveOrderItem order,
  ) {
    if (order.isRide) {
      return (
        title: l10n.homeActiveRide,
        statusText: _getRideStatusText(l10n, order.status),
        icon: Icons.local_taxi,
      );
    }
    if (order.isMessenger) {
      return (
        title: l10n.homeServiceParcel,
        statusText: _getMessengerStatusText(l10n, order.status),
        icon: Icons.local_shipping,
      );
    }
    return (
      title: l10n.homeActiveFood,
      statusText: _getFoodStatusText(l10n, order.status),
      icon: Icons.delivery_dining,
    );
  }

  /// One order opens its own screen. Several open a picker listing every
  /// running order across verticals: the old food-only resume list hid rides
  /// and parcels, so two rides at once landed on an empty food screen.
  void _openOrder(
    BuildContext context,
    List<ActiveOrderItem> orders,
    ActiveOrderItem order,
  ) {
    if (orders.length == 1) {
      _openSingle(context, order);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l10n.homeActiveOrdersTitle,
                  style: AppTypography.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = orders[i];
                    final d = _describe(l10n, item);
                    return Material(
                      color: const Color(0xFFFEF4F5),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(d.icon, color: AppColors.primary),
                        ),
                        title: Text(
                          d.title,
                          style: AppTypography.label1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          d.statusText,
                          style: AppTypography.caption5.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _openSingle(context, item);
                        },
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

  /// Per type (SCRUM-45 §6): RIDE → live ride, FOOD → food tracking,
  /// MESSENGER → parcel tracking.
  void _openSingle(BuildContext context, ActiveOrderItem order) {
    if (order.isRide) {
      context.push('/live/${order.id}');
    } else if (order.isMessenger) {
      context.push('/messenger/tracking/${order.id}');
    } else {
      context.push('/food-order/tracking/${order.id}');
    }
  }

  String _getFoodStatusText(AppLocalizations l10n, String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PLACED':
        return l10n.homeFoodStatusPlaced;
      case 'RESTAURANT_ACCEPTED':
      case 'ACCEPTED':
      case 'CONFIRMING':
        return l10n.homeFoodStatusConfirmed;
      case 'PREPARING':
        return l10n.homeFoodStatusPreparing;
      case 'READY_FOR_PICKUP':
        return l10n.homeFoodStatusReady;
      case 'DRIVER_ASSIGNED':
        return l10n.homeFoodStatusRiderAssigned;
      case 'DRIVER_PICKED_UP':
      case 'PICKED_UP':
        return l10n.homeFoodStatusOnTheWay;
      default:
        return l10n.homeStatusInProgress;
    }
  }

  String _getRideStatusText(AppLocalizations l10n, String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return l10n.homeStatusFindingDriver;
      case 'ACCEPTED':
        return l10n.homeRideStatusAccepted;
      case 'ARRIVED_AT_PICK_UP':
        return l10n.homeRideStatusArrived;
      case 'PICKED_UP':
        return l10n.homeRideStatusOnTrip;
      default:
        return l10n.homeStatusInProgress;
    }
  }

  // Messenger uses ARRIVED_AT_PICKUP — no middle underscore, unlike ride.
  String _getMessengerStatusText(AppLocalizations l10n, String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return l10n.homeStatusFindingDriver;
      case 'ACCEPTED':
        return l10n.homeParcelStatusAccepted;
      case 'ARRIVED_AT_PICKUP':
        return l10n.homeParcelStatusArrived;
      case 'PICKED_UP':
        return l10n.homeParcelStatusDelivering;
      default:
        return l10n.homeStatusInProgress;
    }
  }
}
