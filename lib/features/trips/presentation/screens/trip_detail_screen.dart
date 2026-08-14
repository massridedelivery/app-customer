import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/rating_controller.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/presentation/controllers/trip_detail_controller.dart';
import 'package:customer_app/features/trips/presentation/states/trip_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? orderType;

  const TripDetailScreen({super.key, required this.tripId, this.orderType});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final type = widget.orderType?.toUpperCase() ?? '';
    final notifier = ref.read(tripDetailControllerProvider.notifier);
    if (type == 'RIDE') {
      notifier.fetchRideOrderDetail(widget.tripId);
    } else {
      notifier.fetchFoodOrderDetail(widget.tripId);
    }
  }

  /// "ทำรายการอีกครั้ง": rides re-open booking with the same route; food re-opens
  /// the restaurant (or the food home).
  void _rebook() {
    final state = ref.read(tripDetailControllerProvider);
    final ride = state.rideDetails;
    if (ride != null && ride.dropoffLat != null && ride.dropoffLng != null) {
      final home = ref.read(homeControllerProvider.notifier);
      if (ride.pickupLat != null && ride.pickupLng != null) {
        home.setPickupLocation(
          LatLng(ride.pickupLat!, ride.pickupLng!),
          ride.pickupAddress ?? '',
        );
      }
      home.setDropoffLocation(
        LatLng(ride.dropoffLat!, ride.dropoffLng!),
        ride.dropoffAddress ?? '',
      );
      context.push('/booking');
      return;
    }
    final restaurantId = state.foodDetails?.restaurantId;
    if (restaurantId != null && restaurantId.isNotEmpty) {
      context.push('/restaurant/$restaurantId');
      return;
    }
    context.push('/food-delivery');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripDetailControllerProvider);
    // App-wide cached marker bitmaps (rasterised once per session).
    final pickupIcon = ref.watch(pickupMarkerProvider).value;
    final dropoffIcon = ref.watch(dropoffMarkerProvider).value;

    if (state.isLoading) {
      return const Scaffold(body: Center(child: MassLoadingM(size: 72)));
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดการเดินทาง')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body3,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetails,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.foodDetails == null && state.rideDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดการเดินทาง')),
        body: const Center(child: Text('ไม่พบข้อมูลการจอง')),
      );
    }

    Set<Marker> markers = {};
    Set<Polyline> polylines = {};
    LatLng centerLatLng = MapDefaults.bangkokCenter; // Default Bangkok

    if (state.rideDetails != null) {
      final ride = state.rideDetails!;
      final pLat = ride.pickupLat ?? 0;
      final pLng = ride.pickupLng ?? 0;
      final dLat = ride.dropoffLat ?? 0;
      final dLng = ride.dropoffLng ?? 0;

      if (pLat != 0 && pLng != 0) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pLat, pLng),
            infoWindow: InfoWindow(title: ride.pickupAddress),
            icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
          ),
        );
      }
      if (dLat != 0 && dLng != 0) {
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(dLat, dLng),
            infoWindow: InfoWindow(title: ride.dropoffAddress),
            icon: dropoffIcon ?? BitmapDescriptor.defaultMarker,
          ),
        );
      }
      if (pLat != 0 && dLat != 0) {
        // Centre between pickup & dropoff. No route line on the history map —
        // the straight pickup→dropoff polyline was misleading (not the real
        // route), so we show pins only.
        centerLatLng = LatLng((pLat + dLat) / 2, (pLng + dLng) / 2);
      }
    } else if (state.foodDetails != null) {
      final food = state.foodDetails!;
      final dLat = food.deliveryLat ?? 0;
      final dLng = food.deliveryLng ?? 0;
      if (dLat != 0 && dLng != 0) {
        centerLatLng = LatLng(dLat, dLng);
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(dLat, dLng),
            infoWindow: InfoWindow(title: food.deliveryAddress),
            icon: dropoffIcon ?? BitmapDescriptor.defaultMarker,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(centerLatLng, markers, polylines),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 18),
                _buildBookingCode(state),
                if (state.rideDetails?.driverInfo != null)
                  _buildDriverCard(state.rideDetails!.driverInfo!),
                _buildRouteCard(state),
                if (state.foodDetails != null)
                  _buildFoodItemsCard(state.foodDetails!),
                _buildPaymentCard(state),
                // Rating is ride-only and only for finished trips (food/messenger
                // have their own review flows).
                if (state.rideDetails != null &&
                    state.rideDetails!.status.toUpperCase() == 'COMPLETED')
                  _TripRatingCard(
                    jobId: state.rideDetails!.id,
                    existingRating: state.rideDetails!.ratingByCustomer,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      // Pinned action bar at the bottom.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    LatLng centerLatLng,
    Set<Marker> markers,
    Set<Polyline> polylines,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.semanticGrayNeutralFgHigh,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.primary),
              onPressed: () => context.push('/sos'),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // With no coordinates a live GoogleMap would just show a generic empty
        // Bangkok view with no pins — show a neutral placeholder instead.
        background: markers.isEmpty
            ? Container(
                color: AppColors.foundationBlue100,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 40,
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่มีข้อมูลแผนที่',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnWhite,
                      ),
                    ),
                  ],
                ),
              )
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: centerLatLng,
                  zoom: 13,
                ),
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
      ),
    );
  }

  Widget _buildBookingCode(TripDetailState state) {
    String bookingDate = '';
    String bookingId = '';

    if (state.rideDetails != null) {
      bookingDate = ThaiDateFormatter.dateTime(state.rideDetails!.createdAt);
      bookingId = state.rideDetails!.id;
    } else if (state.foodDetails != null) {
      bookingDate = ThaiDateFormatter.dateTime(state.foodDetails!.placedAt);
      bookingId = state.foodDetails!.id;
    }

    return _buildThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'วันที่การจอง',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                bookingDate,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รหัสการจอง',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: bookingId));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('คัดลอกรหัสการจองแล้ว'),
                          ),
                        );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              bookingId,
                              style: AppTypography.caption4.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.copy,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(HistoryDriverInfo driver) {
    return _buildThemeCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.foundationBlue200,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.semanticGrayNeutralBgWhite,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty
                  ? Image.network(
                      driver.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        color: AppColors.semanticGrayNeutralFgHigh,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppColors.semanticGrayNeutralFgHigh,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName ?? 'ไม่ระบุคนขับ',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.semanticGrayNeutralFgHigh,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (driver.vehiclePlate != null)
                  Text(
                    '${driver.vehicleModel ?? ''} • ${driver.vehiclePlate ?? ''}',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${driver.rating ?? 0.0}',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(TripDetailState state) {
    String distanceStr = '';
    String durationStr = '';
    String pickupLocation = '';
    String pickupTime = '';
    String dropoffLocation = '';
    String dropoffTime = '';

    if (state.rideDetails != null) {
      final ride = state.rideDetails!;
      distanceStr = '${ride.distanceKm?.toStringAsFixed(1) ?? '0'} กม.';
      durationStr = '${ride.totalDurationMin ?? '0'} นาที';
      pickupLocation = ride.pickupAddress ?? '';
      pickupTime = ThaiDateFormatter.time(ride.pickedUpAt ?? ride.createdAt);
      dropoffLocation = ride.dropoffAddress ?? '';
      dropoffTime = ThaiDateFormatter.time(ride.completedAt ?? ride.updatedAt);
    } else if (state.foodDetails != null) {
      final food = state.foodDetails!;
      distanceStr = '${food.customerDistanceKm?.toStringAsFixed(1) ?? '0'} กม.';
      durationStr = '${food.originalEtaMin ?? '0'} นาที';
      pickupLocation = 'ร้านอาหาร';
      pickupTime = ThaiDateFormatter.time(food.placedAt);
      dropoffLocation = food.deliveryAddress ?? '';
      // Only the real delivered time — never fall back to delayQueueUntil, an
      // internal batching timestamp that isn't the customer's dropoff time.
      dropoffTime = ThaiDateFormatter.time(food.deliveredAt);
    }

    return _buildThemeCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รายละเอียดเส้นทาง',
                style: AppTypography.body2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$distanceStr • $durationStr',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLocationRow(
            color: AppColors.foundationGreen500,
            location: pickupLocation,
            time: pickupTime,
            isFirst: true,
          ),
          _buildLocationRow(
            color: AppColors.foundationRed700,
            location: dropoffLocation,
            time: dropoffTime,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemsCard(HistoryFoodDetails food) {
    return _buildThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายการอาหาร',
            style: AppTypography.body2.copyWith(
              color: AppColors.semanticGrayNeutralFgHigh,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: food.items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 16, color: AppColors.foundationBlue200),
            itemBuilder: (context, index) {
              final item = food.items[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          style: AppTypography.body3.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '฿${item.subtotal.toStringAsFixed(0)}',
                        style: AppTypography.body3.copyWith(
                          color: AppColors.semanticGrayNeutralFgHigh,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item.selectedModifiers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.selectedModifiers.map((mod) {
                          return Text(
                            '+ ${mod.name} (+฿${mod.price.toStringAsFixed(0)})',
                            style: AppTypography.caption5.copyWith(
                              color: AppColors.semanticGrayNeutralFgMidOnWhite,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(TripDetailState state) {
    String paymentMethod = '';
    String serviceName = '';
    double total = 0;
    List<Widget> breakdownRows = [];

    if (state.rideDetails != null) {
      final ride = state.rideDetails!;
      paymentMethod = ride.paymentMethod;
      serviceName = ride.bookingType ?? 'การเดินทาง';
      total = ride.fare;

      breakdownRows = [
        _buildPaymentBreakdownRow('ค่าโดยสารเริ่มต้น', ride.fare),
        if (ride.tollFee != null && ride.tollFee! > 0)
          _buildPaymentBreakdownRow('ค่าผ่านทาง', ride.tollFee!),
        if (ride.waitingFee != null && ride.waitingFee! > 0)
          _buildPaymentBreakdownRow('ค่าบริการรอ', ride.waitingFee!),
        if (ride.discount > 0)
          _buildPaymentBreakdownRow('ส่วนลด', -ride.discount),
      ];
    } else if (state.foodDetails != null) {
      final food = state.foodDetails!;
      paymentMethod = food.paymentMethod ?? 'เงินสด';
      serviceName = widget.orderType?.toUpperCase() == 'MART'
          ? 'MassMart'
          : 'MassFood';
      total = food.totalAmount ?? 0;

      breakdownRows = [
        _buildPaymentBreakdownRow('ค่าอาหาร/สินค้า', food.foodTotal ?? 0),
        _buildPaymentBreakdownRow('ค่าบริการจัดส่ง', food.deliveryFee ?? 0),
        if (food.promoDiscount != null && food.promoDiscount! > 0)
          _buildPaymentBreakdownRow('ส่วนลดคูปอง', -food.promoDiscount!),
      ];
    }

    return _buildThemeCard(
      child: Column(
        children: [
          _buildRowInfo(
            icon: Icons.account_balance_wallet_outlined,
            title: paymentMethod,
            subtitle: serviceName,
          ),
          if (breakdownRows.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.foundationBlue200),
            ),
            ...breakdownRows,
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.foundationBlue200),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดรวมสุทธิ',
                style: AppTypography.body2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${total.toStringAsFixed(0)}',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownRow(String label, double amount) {
    final isNegative = amount < 0;
    final amountText = isNegative
        ? '-฿${(-amount).toStringAsFixed(0)}'
        : '฿${amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption4.copyWith(
              color: AppColors.semanticGrayNeutralFgMidOnWhite,
            ),
          ),
          Text(
            amountText,
            style: AppTypography.caption4.copyWith(
              color: isNegative
                  ? AppColors.foundationGreen500
                  : AppColors.semanticGrayNeutralFgHigh,
              fontWeight: isNegative ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required Color color,
    required String location,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AppIcons.asset(AppAssets.icLocationFill,
                  width: 20, height: 20, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.foundationBlue200,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: AppTypography.body3.copyWith(
                      color: AppColors.semanticGrayNeutralFgHigh,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    time,
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.foundationBlue200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.semanticGrayNeutralFgHigh,
            size: 22,
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
                  color: AppColors.semanticGrayNeutralFgHigh,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildThemeCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralBgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }


  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        // Without this the Column tries to fill the bottomNavigationBar's height
        // and pushes the page content off-screen (blank detail page).
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rebook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'ทำรายการอีกครั้ง',
                style: AppTypography.body2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/sos'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'ต้องการความช่วยเหลือ / แจ้งปัญหา',
              style: AppTypography.body3.copyWith(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Post-trip rating card for the history detail screen. Submits to the same
/// endpoint as the live-ride post-trip flow (`POST /api/customer/jobs/{id}/rate`
/// via [RatingController]). Read-only once a rating already exists.
class _TripRatingCard extends ConsumerStatefulWidget {
  final String jobId;
  final double? existingRating;

  const _TripRatingCard({required this.jobId, this.existingRating});

  @override
  ConsumerState<_TripRatingCard> createState() => _TripRatingCardState();
}

class _TripRatingCardState extends ConsumerState<_TripRatingCard> {
  int _selected = 0;
  bool _submitted = false;

  Future<void> _submit() async {
    await ref
        .read(ratingControllerProvider.notifier)
        .submitRating(jobId: widget.jobId, rating: _selected, tags: const []);
    if (!mounted) return;
    // Errors are surfaced via the listener; only flip to the thank-you state on
    // a clean submit.
    if (!ref.read(ratingControllerProvider).hasError) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alreadyRated = (widget.existingRating ?? 0) > 0 || _submitted;
    final submitState = ref.watch(ratingControllerProvider);
    final isSubmitting = submitState.isLoading;

    ref.listen(ratingControllerProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        },
      );
    });

    if (alreadyRated) {
      final value = _submitted ? _selected : widget.existingRating!.round();
      return _card(
        title: 'ขอบคุณสำหรับรีวิว',
        subtitle: 'คุณให้คะแนนการเดินทางนี้แล้ว',
        child: _StarRow(value: value, size: 40),
      );
    }

    return _card(
      title: 'ช่วยเราปรับปรุงประสบการณ์ให้ดียิ่งขึ้น',
      subtitle: 'โดยการให้คะแนนการเดินทางครั้งนี้',
      child: Column(
        children: [
          _StarRow(
            value: _selected,
            size: 44,
            onTap: isSubmitting
                ? null
                : (v) => setState(() => _selected = v),
          ),
          if (_selected > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.foundationGrayscale200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'ส่งรีวิว',
                        style: AppTypography.label1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralBgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body3.copyWith(
              color: AppColors.semanticGrayNeutralFgHigh,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption4.copyWith(
              color: AppColors.semanticGrayNeutralFgMidOnWhite,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

/// Row of five stars. Tappable when [onTap] is provided (1-based value),
/// display-only otherwise.
class _StarRow extends StatelessWidget {
  final int value;
  final double size;
  final ValueChanged<int>? onTap;

  const _StarRow({required this.value, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(i + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? Colors.amber : AppColors.foundationBlue300,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
