import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/widgets/login_required_view.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/layout.dart';
import 'package:customer_app/core/widgets/app_filter_chip.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_history_controller.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/presentation/controllers/trips_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripsScreen extends ConsumerStatefulWidget {
  final HistoryStatus? initialStatus;
  const TripsScreen({super.key, this.initialStatus});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  // All statuses are shown together (ongoing first); only the service type is
  // filtered via the chips.
  HistoryType? _selectedType;
  late final ScrollController _scrollController;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory(isRefresh: true);
    });
    // Server-side changes (e.g. an admin clearing a test account's history)
    // show up on return to the app, not only on pull-to-refresh.
    _lifecycle = AppLifecycleListener(
      onResume: () => _loadHistory(isRefresh: true),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(tripsControllerProvider);
    if (state.isLoadingMore || !state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadHistory(isRefresh: false);
    }
  }

  void _loadHistory({bool isRefresh = true}) {
    // Messenger history has its own source (/api/messenger/customer/orders);
    // the trips /history feed is ride+food only.
    if (_selectedType == HistoryType.messenger) {
      // Messenger source isn't paginated — only (re)fetch on a real refresh,
      // never on load-more scroll ticks.
      if (isRefresh) {
        ref.read(messengerHistoryControllerProvider.notifier).refresh();
      }
      return;
    }
    // ALL (null) and ride/food both use the unified /history feed.
    ref
        .read(tripsControllerProvider.notifier)
        .fetchHistoryOrders(
          type: _selectedType,
          status: null, // all statuses combined
          isRefresh: isRefresh,
        );
    // "ทั้งหมด" also merges in the separate (unpaginated) messenger source —
    // only on refresh, not on every load-more page of the /history feed.
    if (_selectedType == null && isRefresh) {
      ref.read(messengerHistoryControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // History needs an account — a guest sees the login gate in place of the
    // list (App Store 5.1.1) before any token-backed fetch runs.
    if (!ref.watch(authControllerProvider).isAuthenticated) {
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        body: SafeArea(child: LoginRequiredView()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.orderList,
          style: AppTypography.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _TripsFilterBar(
            selectedType: _selectedType,
            onTypeChanged: (type) {
              setState(() {
                _selectedType = type;
              });
              _loadHistory(isRefresh: true);
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(isRefresh: true),
        child: _selectedType == HistoryType.messenger
            ? _MessengerHistoryBody(
                onRetry: () => _loadHistory(isRefresh: true),
              )
            : _selectedType == null
            ? _AllHistoryBody(
                scrollController: _scrollController,
                onRetry: () => _loadHistory(isRefresh: true),
              )
            : _TripsListBody(
                type: _selectedType!,
                scrollController: _scrollController,
                onRetry: () => _loadHistory(isRefresh: true),
              ),
      ),
    );
  }
}

class _TripsFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final HistoryType? selectedType;
  final ValueChanged<HistoryType?> onTypeChanged;

  const _TripsFilterBar({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.semanticGrayNeutralBgWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Type chips only — statuses are combined into one list below.
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "ทั้งหมด" = no type filter (null) → ride+food+messenger merged.
                AppFilterChip(
                  label: l10n.tripFilterAll,
                  selected: selectedType == null,
                  filled: true,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 8),
                _buildTypeChip(HistoryType.food, l10n.tripFilterFood),
                const SizedBox(width: 8),
                _buildTypeChip(HistoryType.ride, l10n.tripFilterRide),
                const SizedBox(width: 8),
                _buildTypeChip(HistoryType.messenger, l10n.tripFilterMessenger),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeChip(HistoryType type, String label) {
    final isSelected = selectedType == type;
    return AppFilterChip(
      label: label,
      selected: isSelected,
      filled: true,
      onTap: () => onTypeChanged(isSelected ? null : type),
    );
  }
}

class _TripsListBody extends ConsumerWidget {
  final HistoryType type;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const _TripsListBody({
    required this.type,
    required this.scrollController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(
      tripsControllerProvider.select((s) => s.historyOrders),
    );
    final isHistoryLoading = ref.watch(
      tripsControllerProvider.select((s) => s.isHistoryLoading),
    );
    final isLoadingMore = ref.watch(
      tripsControllerProvider.select((s) => s.isLoadingMore),
    );
    final historyError = ref.watch(
      tripsControllerProvider.select((s) => s.historyError),
    );

    if (isHistoryLoading && orders.isEmpty) {
      return const Center(child: MassLoadingM(size: 72));
    }

    if (historyError != null && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(friendlyError(historyError)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      // "No trips" only fits rides; the food tab is about orders.
      return Center(
        child: Text(
          type == HistoryType.ride ? l10n.noTripsYet : l10n.noFoodOrdersYet,
        ),
      );
    }

    // Ongoing orders first, then the rest — preserving the API order within
    // each group.
    final sorted = [
      ...orders.where((o) => _isOngoingOrder(o.status)),
      ...orders.where((o) => !_isOngoingOrder(o.status)),
    ];

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: 8,
        // Clear the floating bottom nav so the last row isn't hidden behind it.
        bottom: 8 + kFloatingNavReserve + MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: sorted.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 0.5, color: AppColors.foundationGrayscale100),
      ),
      itemBuilder: (context, index) {
        if (index == sorted.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _OrderListItem(order: sorted[index]);
      },
    );
  }
}

/// True when an order is still in progress (not completed/cancelled/failed).
bool _isOngoingOrder(String status) {
  final s = status.toUpperCase();
  return s != 'COMPLETED' &&
      s != 'SUCCESS' &&
      s != 'CANCELLED' &&
      s != 'FAILED';
}

class _OrderListItem extends ConsumerWidget {
  final HistoryOrder order;

  const _OrderListItem({required this.order});

  // "Book again": rides re-open the booking screen with the same route; food /
  // mart re-open the restaurant (or the food home); anything else falls back to
  // the trip detail.
  void _rebook(BuildContext context, WidgetRef ref) {
    final type = order.type.toUpperCase();
    if (type == 'RIDE' && order.rideDetails != null) {
      final r = order.rideDetails!;
      if (r.dropoffLat != null && r.dropoffLng != null) {
        final home = ref.read(homeControllerProvider.notifier);
        if (r.pickupLat != null && r.pickupLng != null) {
          home.setPickupLocation(
            LatLng(r.pickupLat!, r.pickupLng!),
            r.pickupAddress ?? '',
          );
        }
        home.setDropoffLocation(
          LatLng(r.dropoffLat!, r.dropoffLng!),
          r.dropoffAddress ?? '',
        );
        context.push('/booking');
        return;
      }
    }
    if (type == 'FOOD' || type == 'MART') {
      final restId = order.foodDetails?.restaurantId;
      if (restId != null && restId.isNotEmpty) {
        context.push('/restaurant/$restId');
        return;
      }
      context.push('/food-delivery');
      return;
    }
    context.push('/trip/${order.id}?type=${order.type}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCancelled =
        order.status.toUpperCase() == 'CANCELLED' ||
        order.status.toUpperCase() == 'FAILED';

    final String serviceAsset;
    final typeUpper = order.type.toUpperCase();
    if (typeUpper == 'RIDE') {
      serviceAsset = AppAssets.ic3dRide;
    } else if (typeUpper == 'FOOD' || typeUpper == 'MART') {
      serviceAsset = AppAssets.ic3dFood;
    } else {
      serviceAsset = AppAssets.ic3dMessenger;
    }

    String title = '';
    if (order.type.toUpperCase() == 'FOOD' && order.foodDetails != null) {
      final food = order.foodDetails!;
      final itemsSummary = food.items.map((i) => i.name).join(', ');
      title = itemsSummary.isNotEmpty
          ? l10n.tripTitleTo(itemsSummary, food.deliveryAddress ?? '')
          : l10n.tripFoodOrderTo(food.deliveryAddress ?? '');
    } else if (order.type.toUpperCase() == 'RIDE' &&
        order.rideDetails != null) {
      final ride = order.rideDetails!;
      title = l10n.tripTitleTo(
        ride.pickupAddress ?? '',
        ride.dropoffAddress ?? '',
      );
    } else if (order.type.toUpperCase() == 'MART' &&
        order.foodDetails != null) {
      final food = order.foodDetails!;
      final itemsSummary = food.items.map((i) => i.name).join(', ');
      title = itemsSummary.isNotEmpty
          ? l10n.tripMartItemsTo(itemsSummary, food.deliveryAddress ?? '')
          : l10n.tripMartOrderTo(food.deliveryAddress ?? '');
    } else {
      title = l10n.tripOrderNumber(order.id);
    }

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          context.push('/trip/${order.id}?type=${order.type}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Service Icon (3D brand art)
              Image.asset(serviceAsset, width: 44, height: 44),
              const SizedBox(width: 16),
              // Middle Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDates.of(context).isoDateTime(order.createdAt),
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status on the left, "จองอีกครั้ง" pinned to the far right
                    // of the same line.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(child: _StatusText(status: order.status)),
                        GestureDetector(
                          onTap: () => _rebook(context, ref),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.bookAgain,
                                style: AppTypography.label2.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Price
              Text(
                // A ride's list total from the backend is its bare fare; show
                // what the rider paid instead, as on the trip detail.
                '฿${(order.rideDetails?.payable ?? order.totalAmount).toStringAsFixed(0)}',
                style: AppTypography.body3.copyWith(
                  fontWeight: isCancelled ? FontWeight.normal : FontWeight.bold,
                  color: isCancelled
                      ? AppColors.semanticGrayNeutralFgLowOnWhite
                      : AppColors.semanticGrayNeutralFgHigh,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String status;

  const _StatusText({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = status.toUpperCase();
    if (s == 'COMPLETED' || s == 'SUCCESS') {
      return Text(
        l10n.completed,
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationGreen500,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (s == 'CANCELLED' || s == 'FAILED') {
      return Text(
        l10n.cancelledLabel,
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationRed700,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        _ongoingLabel(l10n, s),
        style: AppTypography.caption4.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // Localized labels for in-progress ride/food statuses (terminal ones
  // handled above) so the list never shows a raw English enum.
  String _ongoingLabel(AppLocalizations l10n, String s) {
    switch (s) {
      case 'PENDING':
        return l10n.tripStatusFindingDriver;
      case 'ACCEPTED':
      case 'CONFIRMING':
        return l10n.tripStatusDriverAccepted;
      case 'ARRIVED_AT_PICK_UP':
      case 'ARRIVED_AT_PICKUP':
        return l10n.tripStatusDriverAtPickup;
      case 'PICKED_UP':
        return l10n.tripStatusOnTrip;
      case 'PREPARING':
        return l10n.tripStatusPreparing;
      case 'READY_FOR_PICKUP':
        return l10n.tripStatusReadyForPickup;
      case 'DRIVER_ASSIGNED':
        return l10n.tripStatusDriverAssigned;
      case 'DELIVERING':
      case 'ON_THE_WAY':
        return l10n.tripStatusDelivering;
      default:
        return l10n.tripStatusInProgress;
    }
  }
}

/// Messenger history list — sourced from `/api/messenger/customer/orders`
/// and filtered client-side by the shared status tabs.
class _MessengerHistoryBody extends ConsumerWidget {
  final VoidCallback onRetry;

  const _MessengerHistoryBody({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(messengerHistoryControllerProvider);

    return ordersAsync.when(
      loading: () => const Center(child: MassLoadingM(size: 72)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(friendlyError(err)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
      data: (orders) {
        // Ongoing first, then the rest.
        final filtered = [
          ...orders.where((o) => !o.isTerminal),
          ...orders.where((o) => o.isTerminal),
        ];
        if (filtered.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Text(AppLocalizations.of(context)!.noDeliveriesYet),
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(
        top: 8,
        // Clear the floating bottom nav so the last row isn't hidden behind it.
        bottom: 8 + kFloatingNavReserve + MediaQuery.of(context).viewPadding.bottom,
      ),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0.5, color: AppColors.foundationGrayscale100),
          ),
          itemBuilder: (context, index) =>
              _MessengerOrderListItem(order: filtered[index]),
        );
      },
    );
  }
}

class _MessengerOrderListItem extends ConsumerWidget {
  final MessengerOrder order;

  const _MessengerOrderListItem({required this.order});

  void _rebook(BuildContext context, WidgetRef ref) {
    final home = ref.read(homeControllerProvider.notifier);
    if (order.pickupLat != 0 && order.pickupLng != 0) {
      home.setPickupLocation(
        LatLng(order.pickupLat, order.pickupLng),
        order.pickupAddress,
      );
    }
    if (order.dropoffLat != 0 && order.dropoffLng != 0) {
      home.setDropoffLocation(
        LatLng(order.dropoffLat, order.dropoffLng),
        order.dropoffAddress,
      );
    }
    context.push('/messenger-booking');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dropoff = order.dropoffAddress.isNotEmpty
        ? order.dropoffAddress
        : l10n.tripParcelDropoffFallback;
    final title = l10n.tripParcelTo(dropoff);

    return RepaintBoundary(
      child: InkWell(
        // Tracking screen doubles as the detail view — it renders DELIVERED
        // and CANCELLED states, not just live orders.
        onTap: () => context.push('/messenger/tracking/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(AppAssets.ic3dMessenger, width: 44, height: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDates.of(context).isoDateTime(order.createdAt),
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(child: _MessengerStatusText(order: order)),
                        GestureDetector(
                          onTap: () => _rebook(context, ref),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.bookAgain,
                                style: AppTypography.label2.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '฿${order.amountDue.toStringAsFixed(0)}',
                style: AppTypography.body3.copyWith(
                  fontWeight: order.isCancelled
                      ? FontWeight.normal
                      : FontWeight.bold,
                  color: order.isCancelled
                      ? AppColors.semanticGrayNeutralFgLowOnWhite
                      : AppColors.semanticGrayNeutralFgHigh,
                  decoration: order.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessengerStatusText extends StatelessWidget {
  final MessengerOrder order;

  const _MessengerStatusText({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (order.isDelivered) {
      return Text(
        l10n.completed,
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationGreen500,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (order.isCancelled) {
      return Text(
        l10n.cancelledLabel,
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationRed700,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text(
      _ongoingLabel(l10n, order.status),
      style: AppTypography.caption4.copyWith(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _ongoingLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.tripStatusFindingDriver;
      case 'ACCEPTED':
        return l10n.tripStatusDriverAccepted;
      case 'ARRIVED_AT_PICKUP':
        return l10n.tripStatusAtParcelPickup;
      case 'PICKED_UP':
        return l10n.tripStatusParcelEnRoute;
      default:
        return l10n.tripStatusInProgress;
    }
  }
}

// ─── "ทั้งหมด" (all) tab ──────────────────────────────────────────────────────
// The unified /history feed only covers ride+food, and messenger has a separate
// source/model, so the ALL tab merges the two client-side. A small sealed union
// lets one sorted list reuse both existing row widgets unchanged.
sealed class _FeedItem {
  DateTime get sortDate;
  bool get isOngoing;
}

class _TripItem extends _FeedItem {
  final HistoryOrder order;
  _TripItem(this.order);
  @override
  DateTime get sortDate =>
      DateTime.tryParse(order.createdAt) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  @override
  bool get isOngoing => _isOngoingOrder(order.status);
}

class _MsgrItem extends _FeedItem {
  final MessengerOrder order;
  _MsgrItem(this.order);
  @override
  DateTime get sortDate =>
      DateTime.tryParse(order.createdAt) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  @override
  bool get isOngoing => !order.isTerminal;
}

class _AllHistoryBody extends ConsumerWidget {
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const _AllHistoryBody({
    required this.scrollController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(
      tripsControllerProvider.select((s) => s.historyOrders),
    );
    final tripsLoading = ref.watch(
      tripsControllerProvider.select((s) => s.isHistoryLoading),
    );
    final tripsError = ref.watch(
      tripsControllerProvider.select((s) => s.historyError),
    );
    final isLoadingMore = ref.watch(
      tripsControllerProvider.select((s) => s.isLoadingMore),
    );
    final msgrAsync = ref.watch(messengerHistoryControllerProvider);
    final messenger = msgrAsync.asData?.value ?? const <MessengerOrder>[];

    // Only block on the spinner while BOTH sources are still empty & loading.
    if (trips.isEmpty &&
        messenger.isEmpty &&
        (tripsLoading || msgrAsync.isLoading)) {
      return const Center(child: MassLoadingM(size: 72));
    }

    // Both failed with nothing to show → offer a retry.
    if (trips.isEmpty &&
        messenger.isEmpty &&
        tripsError != null &&
        msgrAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(friendlyError(tripsError)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final merged = <_FeedItem>[
      ...trips.map(_TripItem.new),
      ...messenger.map(_MsgrItem.new),
    ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    // Ongoing first, then the rest — each group already date-desc.
    final sorted = [
      ...merged.where((i) => i.isOngoing),
      ...merged.where((i) => !i.isOngoing),
    ];

    if (sorted.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noOrdersYet));
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: 8,
        // Clear the floating bottom nav so the last row isn't hidden behind it.
        bottom: 8 + kFloatingNavReserve + MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: sorted.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 0.5, color: AppColors.foundationGrayscale100),
      ),
      itemBuilder: (context, index) {
        if (index == sorted.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = sorted[index];
        return switch (item) {
          _TripItem(:final order) => _OrderListItem(order: order),
          _MsgrItem(:final order) => _MessengerOrderListItem(order: order),
        };
      },
    );
  }
}
