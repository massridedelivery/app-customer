import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_tracking_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MessengerTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const MessengerTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<MessengerTrackingScreen> createState() =>
      _MessengerTrackingScreenState();
}

class _MessengerTrackingScreenState
    extends ConsumerState<MessengerTrackingScreen> {
  GoogleMapController? _mapController;
  bool _cameraFitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(messengerTrackingControllerProvider.notifier)
          .startTracking(widget.orderId);
    });
  }

  void _fitCamera(MessengerOrder order) {
    if (_cameraFitted || _mapController == null) return;
    if (order.pickupLat == 0 && order.pickupLng == 0) return;
    _cameraFitted = true;

    final southwest = LatLng(
      order.pickupLat < order.dropoffLat ? order.pickupLat : order.dropoffLat,
      order.pickupLng < order.dropoffLng ? order.pickupLng : order.dropoffLng,
    );
    final northeast = LatLng(
      order.pickupLat > order.dropoffLat ? order.pickupLat : order.dropoffLat,
      order.pickupLng > order.dropoffLng ? order.pickupLng : order.dropoffLng,
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        60,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการส่งพัสดุ', style: AppTypography.heading4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('คุณแน่ใจหรือไม่ว่าต้องการยกเลิก?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'เหตุผล (ไม่บังคับ)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ไม่ใช่', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'ใช่, ยกเลิกเลย',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(messengerTrackingControllerProvider.notifier)
        .cancelOrder(reason: reasonController.text.trim());
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกการส่งพัสดุแล้ว'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerTrackingControllerProvider);
    final order = state.order;

    ref.listen(messengerTrackingControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      final nextOrder = next.order;
      if (nextOrder != null) _fitCamera(nextOrder);
    });

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ติดตามพัสดุ',
          style: AppTypography.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.black),
            onPressed: () => ref
                .read(messengerTrackingControllerProvider.notifier)
                .refresh(),
          ),
        ],
      ),
      body: order == null
          ? _buildLoadingOrError(state.isLoading, state.error)
          : Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.32,
                      child: _buildMap(order),
                    ),
                    Expanded(child: _buildDetailPanel(order)),
                  ],
                ),
                if (state.isCancelling)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLoadingOrError(bool isLoading, String? error) {
    if (isLoading || error == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('ไม่สามารถโหลดข้อมูลได้', style: AppTypography.heading5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTypography.caption4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref
                  .read(messengerTrackingControllerProvider.notifier)
                  .startTracking(widget.orderId),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('ลองใหม่', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(MessengerOrder order) {
    final pickup = LatLng(order.pickupLat, order.pickupLng);
    final dropoff = LatLng(order.dropoffLat, order.dropoffLng);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
      onMapCreated: (controller) {
        _mapController = controller;
        _fitCamera(order);
      },
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'จุดรับพัสดุ'),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'จุดส่งพัสดุ'),
        ),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildDetailPanel(MessengerOrder order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(order),
          const SizedBox(height: 12),
          _buildPackageCard(order),
          const SizedBox(height: 12),
          _buildFareCard(order),
          // Chat opens once a driver accepts — before that there is no
          // counterparty (SCRUM-41 chat notes).
          if (order.hasDriver && !order.isTerminal) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/messenger/chat/${order.id}'),
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'แชทกับคนขับ',
                style: AppTypography.heading6.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          // Review CTA once delivered (SCRUM-41 review endpoint).
          if (order.isDelivered) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/messenger/review/${order.id}'),
              icon: const Icon(
                Icons.star_rate_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'ให้คะแนนการจัดส่ง',
                style: AppTypography.heading6.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (order.isCancellable) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _confirmCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ยกเลิกการส่งพัสดุ',
                style: AppTypography.heading6.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Status ────────────────────────────────────────────────────────────────

  Widget _buildStatusCard(MessengerOrder order) {
    if (order.isCancelled) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel, color: AppColors.error, size: 28),
                const SizedBox(width: 8),
                Text(
                  'ยกเลิกแล้ว',
                  style: AppTypography.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (order.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'เหตุผล: ${order.cancelReason}',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final int activeStep = _statusStep(order.status);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: order.isDelivered
                      ? AppColors.foundationGreen500.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  order.isDelivered
                      ? Icons.check_circle
                      : Icons.local_shipping,
                  color: order.isDelivered
                      ? AppColors.foundationGreen500
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText(order.status),
                      style: AppTypography.heading5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: order.isDelivered
                            ? AppColors.foundationGreen500
                            : AppColors.primary,
                      ),
                    ),
                    if (order.hasDriver) ...[
                      const SizedBox(height: 2),
                      Text(
                        'คนขับ #${order.driverId.substring(0, order.driverId.length.clamp(0, 6))}',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(activeStep),
        ],
      ),
    );
  }

  Widget _buildTimeline(int activeStep) {
    const labels = ['รอคนขับ', 'รับงานแล้ว', 'ถึงจุดรับ', 'กำลังส่ง', 'สำเร็จ'];
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: activeStep >= i
                    ? AppColors.foundationGreen500
                    : AppColors.foundationGrayscale200,
              ),
            ),
          _timelineStep(labels[i], activeStep >= i),
        ],
      ],
    );
  }

  Widget _timelineStep(String title, bool isActive) {
    final color = isActive
        ? AppColors.foundationGreen500
        : AppColors.foundationGrayscale300;
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isActive ? color : AppColors.white,
            border: Border.all(color: color, width: isActive ? 0 : 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.support2.copyWith(
            color: isActive
                ? AppColors.textPrimary
                : AppColors.foundationGrayscale500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ─── Package info ──────────────────────────────────────────────────────────

  Widget _buildPackageCard(MessengerOrder order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลพัสดุ',
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.trip_origin,
            AppColors.foundationGreen500,
            order.pickupAddress.isNotEmpty ? order.pickupAddress : 'จุดรับพัสดุ',
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.location_on,
            AppColors.foundationRed700,
            order.dropoffAddress.isNotEmpty
                ? order.dropoffAddress
                : 'จุดส่งพัสดุ',
          ),
          const Divider(height: 20, color: AppColors.foundationGrayscale200),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'ขนาด ${order.packageSizeTier.toUpperCase()} • ${order.packageWeightKg.toStringAsFixed(1)} กก.',
              ),
              if (order.isCod)
                _chip(
                  'เก็บเงินปลายทาง ฿${order.codAmount.toStringAsFixed(0)}',
                  color: AppColors.foundationOrange800,
                  background: AppColors.foundationOrange100,
                ),
            ],
          ),
          if (order.recipientName.isNotEmpty ||
              order.recipientPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(
              Icons.person_outline,
              AppColors.textSecondary,
              [
                if (order.recipientName.isNotEmpty) order.recipientName,
                if (order.recipientPhone.isNotEmpty) order.recipientPhone,
              ].join(' • '),
            ),
          ],
          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.sticky_note_2_outlined, AppColors.textSecondary,
                order.notes),
          ],
        ],
      ),
    );
  }

  // ─── Fare ──────────────────────────────────────────────────────────────────

  Widget _buildFareCard(MessengerOrder order) {
    return _card(
      child: Column(
        children: [
          _fareRow(
            'ค่าส่ง (${order.distanceKm.toStringAsFixed(1)} กม.)',
            '฿${order.fare.toStringAsFixed(0)}',
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _fareRow(
              'ส่วนลด',
              '-฿${order.discount.toStringAsFixed(0)}',
              valueColor: AppColors.foundationGreen500,
            ),
          ],
          const Divider(height: 16, color: AppColors.foundationGrayscale200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดชำระ (${_paymentLabel(order)})',
                style: AppTypography.body2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${order.amountDue.toStringAsFixed(0)}',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body2.copyWith(color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, {Color? color, Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.caption4.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _paymentLabel(MessengerOrder order) {
    switch (order.paymentMethod.toUpperCase()) {
      case 'COD':
        return 'เก็บเงินปลายทาง';
      case 'PROMPTPAY':
        return 'พร้อมเพย์';
      default:
        return 'เงินสด';
    }
  }

  int _statusStep(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'ARRIVED_AT_PICKUP':
        return 2;
      case 'PICKED_UP':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 0;
    }
  }

  String _statusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'กำลังค้นหาคนขับ...';
      case 'ACCEPTED':
        return 'คนขับรับงานแล้ว กำลังไปจุดรับ';
      case 'ARRIVED_AT_PICKUP':
        return 'คนขับถึงจุดรับพัสดุแล้ว';
      case 'PICKED_UP':
        return 'รับพัสดุแล้ว กำลังนำส่ง';
      case 'DELIVERED':
        return 'ส่งพัสดุสำเร็จ';
      default:
        return 'กำลังดำเนินการ...';
    }
  }
}
