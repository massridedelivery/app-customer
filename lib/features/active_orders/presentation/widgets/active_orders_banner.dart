import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';
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
        final String statusText;
        final String title;
        final IconData icon;
        if (order.isRide) {
          statusText = _getRideStatusText(order.status);
          title = 'การเดินทางของคุณ';
          icon = Icons.local_taxi;
        } else if (order.isMessenger) {
          statusText = _getMessengerStatusText(order.status);
          title = 'ส่งพัสดุ';
          icon = Icons.local_shipping;
        } else {
          statusText = _getFoodStatusText(order.status);
          title = 'ร้านอาหาร';
          icon = Icons.delivery_dining;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
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

                    // Center Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: AppTypography.heading6.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (orders.length > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: AppTypography.caption4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            'ดูสถานะ',
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

  /// Branch on type per SCRUM-45 §6: RIDE → live ride, FOOD → tracking,
  /// MESSENGER → package tracking; several running at once → the resume list
  /// (food-only for now, so a messenger item always opens directly).
  void _openOrder(
    BuildContext context,
    List<ActiveOrderItem> orders,
    ActiveOrderItem order,
  ) {
    if (order.isMessenger) {
      context.push('/messenger/tracking/${order.id}');
      return;
    }
    if (orders.length == 1) {
      if (order.isRide) {
        context.push('/live/${order.id}');
      } else {
        context.push('/food-order/tracking/${order.id}');
      }
    } else {
      context.push('/food-order/resume');
    }
  }

  String _getFoodStatusText(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PLACED':
        return 'กำลังส่งคำสั่งซื้อ...';
      case 'RESTAURANT_ACCEPTED':
      case 'ACCEPTED':
      case 'CONFIRMING':
        return 'ยืนยันการสั่งซื้อแล้ว';
      case 'PREPARING':
        return 'ร้านอาหารกำลังเตรียมอาหาร...';
      case 'READY_FOR_PICKUP':
        return 'ปรุงเสร็จแล้ว - รอรับอาหาร';
      case 'DRIVER_ASSIGNED':
        return 'จับคู่คนส่งอาหารสำเร็จ';
      case 'DRIVER_PICKED_UP':
      case 'PICKED_UP':
        return 'คนขับกำลังจัดส่งอาหารให้คุณ';
      default:
        return 'กำลังดำเนินการ...';
    }
  }

  String _getRideStatusText(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'กำลังค้นหาคนขับ...';
      case 'ACCEPTED':
        return 'คนขับตอบรับแล้ว';
      case 'ARRIVED_AT_PICK_UP':
        return 'คนขับถึงจุดรับแล้ว';
      case 'PICKED_UP':
        return 'กำลังเดินทาง';
      default:
        return 'กำลังดำเนินการ...';
    }
  }

  // Messenger uses ARRIVED_AT_PICKUP — no middle underscore, unlike ride.
  String _getMessengerStatusText(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'กำลังค้นหาคนขับ...';
      case 'ACCEPTED':
        return 'คนขับรับงานแล้ว';
      case 'ARRIVED_AT_PICKUP':
        return 'คนขับถึงจุดรับพัสดุ';
      case 'PICKED_UP':
        return 'กำลังนำส่งพัสดุ';
      default:
        return 'กำลังดำเนินการ...';
    }
  }
}
