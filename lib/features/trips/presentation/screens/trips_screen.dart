import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
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
  late HistoryStatus _selectedStatus;
  HistoryType? _selectedType;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? HistoryStatus.ongoing;
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory(isRefresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant TripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != null &&
        widget.initialStatus != oldWidget.initialStatus) {
      setState(() {
        _selectedStatus = widget.initialStatus!;
      });
      _loadHistory(isRefresh: true);
    }
  }

  @override
  void dispose() {
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
      ref.read(messengerHistoryControllerProvider.notifier).refresh();
      return;
    }
    ref
        .read(tripsControllerProvider.notifier)
        .fetchHistoryOrders(
          type: _selectedType,
          status: _selectedStatus,
          isRefresh: isRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
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
          preferredSize: const Size.fromHeight(115),
          child: _TripsFilterBar(
            selectedStatus: _selectedStatus,
            selectedType: _selectedType,
            onStatusChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
              _loadHistory(isRefresh: true);
            },
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
                status: _selectedStatus,
                onRetry: () => _loadHistory(isRefresh: true),
              )
            : _TripsListBody(
                scrollController: _scrollController,
                onRetry: () => _loadHistory(isRefresh: true),
              ),
      ),
    );
  }
}

class _TripsFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final HistoryStatus selectedStatus;
  final HistoryType? selectedType;
  final ValueChanged<HistoryStatus> onStatusChanged;
  final ValueChanged<HistoryType?> onTypeChanged;

  const _TripsFilterBar({
    required this.selectedStatus,
    required this.selectedType,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(115);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.semanticGrayNeutralBgWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Status Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatusTab(HistoryStatus.ongoing, 'Ongoing'),
                const SizedBox(width: 24),
                _buildStatusTab(HistoryStatus.completed, 'Completed'),
                const SizedBox(width: 24),
                _buildStatusTab(HistoryStatus.canceled, 'Canceled/Failed'),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.foundationGrayscale200,
          ),
          const SizedBox(height: 8),
          // Bottom Row: Type Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _buildTypeChip(HistoryType.food, 'Food Delivery'),
                const SizedBox(width: 8),
                _buildTypeChip(HistoryType.ride, 'Ride'),
                const SizedBox(width: 8),
                _buildTypeChip(HistoryType.messenger, 'Messenger'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusTab(HistoryStatus status, String label) {
    final isSelected = selectedStatus == status;
    const activeColor = AppColors.primary;
    final inactiveColor = AppColors.semanticGrayNeutralFgLowOnWhite;

    return GestureDetector(
      onTap: () {
        if (selectedStatus != status) {
          onStatusChanged(status);
        }
      },
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: AppTypography.body2.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(1.5),
                  topRight: Radius.circular(1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(HistoryType type, String label) {
    final isSelected = selectedType == type;
    const themeRed = AppColors.primary;

    return GestureDetector(
      onTap: () {
        onTypeChanged(isSelected ? null : type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.foundationRed100 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeRed : AppColors.foundationGrayscale300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.label2.copyWith(
              color: isSelected
                  ? themeRed
                  : AppColors.semanticGrayNeutralFgHigh,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripsListBody extends ConsumerWidget {
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const _TripsListBody({required this.scrollController, required this.onRetry});

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
      return const Center(child: CircularProgressIndicator());
    }

    if (historyError != null && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(historyError),
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
      return Center(child: Text(AppLocalizations.of(context)!.noTripsYet));
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 0.5, color: AppColors.foundationGrayscale100),
      ),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final order = orders[index];
        return _OrderListItem(order: order);
      },
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final HistoryOrder order;

  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled =
        order.status.toUpperCase() == 'CANCELLED' ||
        order.status.toUpperCase() == 'FAILED';

    IconData serviceIcon;
    if (order.type.toUpperCase() == 'RIDE') {
      serviceIcon = Icons.directions_car;
    } else if (order.type.toUpperCase() == 'FOOD') {
      serviceIcon = Icons.pedal_bike_sharp;
    } else {
      serviceIcon = Icons.shopping_basket;
    }

    String title = '';
    if (order.type.toUpperCase() == 'FOOD' && order.foodDetails != null) {
      final food = order.foodDetails!;
      final itemsSummary = food.items.map((i) => i.name).join(', ');
      title = itemsSummary.isNotEmpty
          ? '$itemsSummary ไป ${food.deliveryAddress ?? ''}'
          : 'คำสั่งซื้ออาหาร ไป ${food.deliveryAddress ?? ''}';
    } else if (order.type.toUpperCase() == 'RIDE' &&
        order.rideDetails != null) {
      final ride = order.rideDetails!;
      title = '${ride.pickupAddress ?? ''} ไป ${ride.dropoffAddress ?? ''}';
    } else if (order.type.toUpperCase() == 'MART' &&
        order.foodDetails != null) {
      final food = order.foodDetails!;
      final itemsSummary = food.items.map((i) => i.name).join(', ');
      title = itemsSummary.isNotEmpty
          ? 'ซื้อของ: $itemsSummary ไป ${food.deliveryAddress ?? ''}'
          : 'คำสั่งซื้อของใช้ ไป ${food.deliveryAddress ?? ''}';
    } else {
      title = 'คำสั่งซื้อ #${order.id}';
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
              // Left Service Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(serviceIcon, color: AppColors.white, size: 24),
              ),
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
                      order.formattedCreatedAt,
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusText(status: order.status),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Price
              Text(
                '฿${order.totalAmount.toStringAsFixed(0)}',
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
    final s = status.toUpperCase();
    if (s == 'COMPLETED' || s == 'SUCCESS') {
      return Text(
        'สำเร็จ',
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationGreen500,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (s == 'CANCELLED' || s == 'FAILED') {
      return Text(
        'ถูกยกเลิก',
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationRed700,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        status,
        style: AppTypography.caption4.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}

/// Messenger history list — sourced from `/api/messenger/customer/orders`
/// and filtered client-side by the shared status tabs.
class _MessengerHistoryBody extends ConsumerWidget {
  final HistoryStatus status;
  final VoidCallback onRetry;

  const _MessengerHistoryBody({required this.status, required this.onRetry});

  bool _matchesStatus(MessengerOrder order) {
    switch (status) {
      case HistoryStatus.ongoing:
        return !order.isTerminal;
      case HistoryStatus.completed:
        return order.isDelivered;
      case HistoryStatus.canceled:
        return order.isCancelled;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(messengerHistoryControllerProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(err.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
      data: (orders) {
        final filtered = orders.where(_matchesStatus).toList();
        if (filtered.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Text(AppLocalizations.of(context)!.noTripsYet),
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
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

class _MessengerOrderListItem extends StatelessWidget {
  final MessengerOrder order;

  const _MessengerOrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final dropoff = order.dropoffAddress.isNotEmpty
        ? order.dropoffAddress
        : 'จุดส่งพัสดุ';
    final title = 'ส่งพัสดุ ไป $dropoff';

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
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
                      order.formattedCreatedAt,
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MessengerStatusText(order: order),
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
    if (order.isDelivered) {
      return Text(
        'สำเร็จ',
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationGreen500,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (order.isCancelled) {
      return Text(
        'ถูกยกเลิก',
        style: AppTypography.caption4.copyWith(
          color: AppColors.foundationRed700,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text(
      _ongoingLabel(order.status),
      style: AppTypography.caption4.copyWith(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _ongoingLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'กำลังหาคนขับ';
      case 'ACCEPTED':
        return 'คนขับรับงานแล้ว';
      case 'ARRIVED_AT_PICKUP':
        return 'ถึงจุดรับพัสดุ';
      case 'PICKED_UP':
        return 'กำลังนำส่ง';
      default:
        return 'กำลังดำเนินการ';
    }
  }
}
