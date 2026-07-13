import 'dart:async';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_map.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_rider.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_location_details.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_order_summary.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_payment_method.dart';
import 'package:customer_app/features/food_order/presentation/widgets/live_food_tracking_cancel_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum OrderState { finding, confirming, preparing, delivery, delivered }

class LiveFoodTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveFoodTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveFoodTrackingScreen> createState() =>
      _LiveFoodTrackingScreenState();
}

class _LiveFoodTrackingScreenState
    extends ConsumerState<LiveFoodTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(liveFoodTrackingControllerProvider.notifier)
          .startTracking(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderStatus = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.orderStatus),
    );

    final isCancelled =
        orderStatus == 'CANCELLED' ||
        orderStatus == 'RESTAURANT_REJECTED';

    if (isCancelled) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'สถานะคำสั่งซื้อ',
            style: AppTypography.heading4.copyWith(color: AppColors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/main'),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.foundationRed100.withValues(alpha: 0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.foundationRed200.withValues(
                            alpha: 0.6,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.foundationRed300.withValues(
                            alpha: 0.8,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.foundationRed700,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.foundationRed700,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: AppColors.foundationGrayscale200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        orderStatus == 'RESTAURANT_REJECTED'
                            ? 'ขออภัย ร้านค้าปฏิเสธคำสั่งซื้อ'
                            : 'คำสั่งซื้อนี้ถูกยกเลิกแล้ว',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.foundationRed700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        orderStatus == 'RESTAURANT_REJECTED'
                            ? 'ร้านอาหารปฏิเสธรายการสั่งซื้อนี้เนื่องจากมีเมนูบางรายการหมด หรืออยู่นอกเวลาให้บริการ คุณสามารถกลับไปเลือกซื้ออาหารจากร้านอื่นต่อได้ค่ะ'
                            : 'รายการสั่งซื้อนี้ถูกยกเลิกเรียบร้อยแล้ว หากคุณชำระเงินล่วงหน้าแล้ว ระบบจะดำเนินการคืนเงินเข้าช่องทางเดิมภายในเวลาที่กำหนด',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.semanticGrayNeutralFgLowOnGray,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/main'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'กลับสู่หน้าหลัก',
                          style: AppTypography.heading5.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go('/main?tab=1&status=canceled'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.foundationGrayscale300,
                          ),
                          foregroundColor: AppColors.foundationGrayscale800,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'ดูประวัติการสั่งซื้อ',
                          style: AppTypography.heading5.copyWith(
                            color: AppColors.foundationGrayscale800,
                          ),
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
    OrderState currentState;
    switch (orderStatus) {
      case 'PLACED':
        currentState = OrderState.finding;
        break;
      case 'RESTAURANT_ACCEPTED':
      case 'ACCEPTED':
      case 'CONFIRMING':
        currentState = OrderState.confirming;
        break;
      case 'PREPARING':
      case 'READY_FOR_PICKUP':
        currentState = OrderState.preparing;
        break;
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_PICKED_UP':
      case 'PICKED_UP':
        currentState = OrderState.delivery;
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        currentState = OrderState.delivered;
        break;
      default:
        currentState = OrderState.finding;
    }

    ref.listen(
      liveFoodTrackingControllerProvider.select((s) => s.orderStatus),
      (previous, next) {
        final wasFinished = previous == 'COMPLETED' || previous == 'DELIVERED';
        final isFinished = next == 'COMPLETED' || next == 'DELIVERED';
        if (isFinished && !wasFinished) {
          Future.delayed(const Duration(seconds: 4), () {
            if (context.mounted) {
              context.pushReplacement('/food-order/receipt/${widget.orderId}');
            }
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveFoodTrackingMap(
              orderId: widget.orderId,
              currentState: currentState,
              // App-wide cached marker bitmaps (rasterised once per session).
              restaurantIcon: ref.watch(pickupMarkerProvider).value,
              customerIcon: ref.watch(dropoffMarkerProvider).value,
            ),
          ),

          if (currentState != OrderState.delivery && currentState != OrderState.delivered)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: _buildTopIllustration(currentState),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: (currentState == OrderState.delivery || currentState == OrderState.delivered)
                  ? MediaQuery.of(context).size.height * 0.55
                  : MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderTitle(currentState),
                          const SizedBox(height: 16),
                          _buildTimeline(currentState),
                          const SizedBox(height: 16),
                          Text(
                            'เลขการสั่งซื้อ-$_orderNumber',
                            style: AppTypography.caption5.copyWith(
                              color: AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (currentState == OrderState.finding)
                            _buildFindingModeContent(currentState)
                          else
                            _buildConfirmedModeContent(currentState),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.go('/main'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.semanticGrayNeutralFgHigh,
                    ),
                  ),
                ),
                const LiveFoodTrackingCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _orderNumber => widget.orderId.toUpperCase();

  Widget _buildHeaderTitle(OrderState currentState) {
    String title = '';
    String subtitle = '';

    switch (currentState) {
      case OrderState.finding:
        title = 'กำลังค้นหาคนรับออเดอร์';
        subtitle = 'กำลังหาคนขับจัดส่งอาหารให้คุณ...';
        break;
      case OrderState.confirming:
        title = 'กำลังรอการยืนยันจากร้านค้า';
        subtitle = 'กำลังรอร้านค้าตอบรับคำสั่งซื้อ...';
        break;
      case OrderState.preparing:
        title = 'กำลังเตรียมคำสั่งซื้อ';
        subtitle = 'ร้านกำลังปรุงอาหารของคุณอย่างพิถีพิถัน';
        break;
      case OrderState.delivery:
        title = 'กำลังเดินทางไปยังที่หมาย';
        subtitle = 'คนขับกำลังนำอาหารส่งไปที่จุดรับของคุณ';
        break;
      case OrderState.delivered:
        title = 'จัดส่งสำเร็จ';
        subtitle = 'อาหารของคุณจัดส่งถึงที่หมายเรียบร้อยแล้ว';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            color: AppColors.foundationGreen700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(OrderState currentState) {
    int activeStep = -1;
    if (currentState == OrderState.confirming) activeStep = 0;
    if (currentState == OrderState.preparing) activeStep = 1;
    if (currentState == OrderState.delivery) activeStep = 2;
    if (currentState == OrderState.delivered) activeStep = 3;

    return Row(
      children: [
        _buildTimelineIcon(Icons.store, 0 <= activeStep, isBox: true),
        _buildTimelineLine(
          isGreen: 0 < activeStep,
          isAnimating: 0 == activeStep,
        ),
        _buildTimelineIcon(Icons.shopping_basket, 1 <= activeStep),
        _buildTimelineLine(
          isGreen: 1 < activeStep,
          isAnimating: 1 == activeStep,
        ),
        _buildTimelineIcon(Icons.moped, 2 <= activeStep),
        _buildTimelineLine(
          isGreen: 2 < activeStep,
          isAnimating: 2 == activeStep,
        ),
        _buildTimelineIcon(Icons.location_on, 3 <= activeStep),
      ],
    );
  }

  Widget _buildTimelineIcon(
    IconData icon,
    bool isActive, {
    bool isBox = false,
  }) {
    Color color = isActive
        ? AppColors.foundationGreen600
        : Colors.grey.shade400;
    if (isBox) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      );
    }
    return Icon(icon, size: 24, color: color);
  }

  Widget _buildTimelineLine({required bool isGreen, bool isAnimating = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: isAnimating
              ? LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.foundationGreen400,
                  ),
                )
              : Container(
                  color: isGreen
                      ? AppColors.foundationGreen400
                      : Colors.grey.shade200,
                ),
        ),
      ),
    );
  }

  Widget _buildTopIllustration(OrderState currentState) {
    Color bg;
    IconData icon;
    if (currentState == OrderState.finding) {
      bg = const Color(0xFFE3F2FD);
      icon = Icons.directions_run;
    } else if (currentState == OrderState.confirming) {
      bg = const Color(0xFFE8F5E9);
      icon = Icons.storefront;
    } else {
      bg = const Color(0xFFFFF8E1);
      icon = Icons.soup_kitchen;
    }

    return Container(
      color: bg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 60,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.location_city, size: 160, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Icon(icon, size: 64, color: AppColors.foundationGreen500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingModeContent(OrderState currentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LiveFoodTrackingLocationDetails(),
        const SizedBox(height: 16),
        LiveFoodTrackingOrderSummary(currentState: currentState),
        const SizedBox(height: 16),
        const LiveFoodTrackingPaymentMethod(),
      ],
    );
  }

  Widget _buildConfirmedModeContent(OrderState currentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiveFoodTrackingRider(orderId: widget.orderId),
        const SizedBox(height: 16),
        const LiveFoodTrackingLocationDetails(),
        const SizedBox(height: 16),
        LiveFoodTrackingOrderSummary(currentState: currentState),
        const SizedBox(height: 16),
        const LiveFoodTrackingPaymentMethod(),
      ],
    );
  }
}
