import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/active_orders/domain/models/active_order_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Card for one in-progress food order, rendered from the lean
/// `/api/customer/active` item (SCRUM-45) — full detail lives on the
/// tracking screen it links to.
class ResumeOrderCard extends StatelessWidget {
  final ActiveOrderItem order;
  final Function(String) onCancel;

  const ResumeOrderCard({
    super.key,
    required this.order,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final String statusText = _getStatusText(order.status);
    final Color statusColor = _getStatusColor(order.status);
    final int activeStep = _getActiveTimelineStep(order.status);
    final String orderRef = order.id.isNotEmpty
        ? 'คำสั่งซื้อ #${order.id.substring(0, order.id.length.clamp(0, 6))}'
        : 'คำสั่งซื้อ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.foundationGrayscale200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderRef,
                        style: AppTypography.heading5.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'สั่งเมื่อ: ${order.formattedCreatedAt}',
                        style: AppTypography.caption5.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.caption4.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.foundationGrayscale200),

          // Timeline section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: _buildMiniTimeline(activeStep),
          ),

          // Action buttons section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Cancel Button (Only if Placed)
                if (order.status.toUpperCase() == 'PLACED') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(order.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.foundationGrayscale300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: AppTypography.heading6.copyWith(
                          color: AppColors.foundationGrayscale800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Chat with driver if assigned
                if (order.hasDriver) ...[
                  IconButton(
                    onPressed: () => context.push('/food-order/chat/${order.id}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Track button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/food-order/tracking/${order.id}'),
                    icon: const Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                    label: Text(
                      'ติดตามสถานะ',
                      style: AppTypography.heading6.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTimeline(int activeStep) {
    return Row(
      children: [
        _buildTimelineStep('สั่งซื้อแล้ว', activeStep >= 0, isFirst: true),
        _buildTimelineDivider(activeStep >= 1),
        _buildTimelineStep('กำลังเตรียม', activeStep >= 1),
        _buildTimelineDivider(activeStep >= 2),
        _buildTimelineStep('กำลังส่ง', activeStep >= 2, isLast: true),
      ],
    );
  }

  Widget _buildTimelineStep(String title, bool isActive, {bool isFirst = false, bool isLast = false}) {
    final Color color = isActive ? AppColors.foundationGreen500 : AppColors.foundationGrayscale300;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isActive ? color : AppColors.white,
              border: Border.all(
                color: color,
                width: isActive ? 0 : 2,
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.support2.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.foundationGrayscale500,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider(bool isActive) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isActive ? AppColors.foundationGreen500 : AppColors.foundationGrayscale200,
    );
  }

  String _getStatusText(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PLACED':
        return 'สั่งซื้อแล้ว';
      case 'RESTAURANT_ACCEPTED':
      case 'ACCEPTED':
      case 'CONFIRMING':
        return 'ยืนยันแล้ว';
      case 'PREPARING':
        return 'กำลังปรุงอาหาร';
      case 'READY_FOR_PICKUP':
        return 'ปรุงเสร็จแล้ว';
      case 'DRIVER_ASSIGNED':
        return 'ได้คนขับแล้ว';
      case 'DRIVER_PICKED_UP':
      case 'PICKED_UP':
        return 'กำลังส่งอาหาร';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PLACED':
        return Colors.orange;
      case 'PREPARING':
        return Colors.amber.shade700;
      case 'READY_FOR_PICKUP':
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_PICKED_UP':
      case 'PICKED_UP':
        return AppColors.foundationGreen500;
      default:
        return AppColors.primary;
    }
  }

  int _getActiveTimelineStep(String status) {
    final s = status.toUpperCase();
    if (s == 'PREPARING' || s == 'READY_FOR_PICKUP') {
      return 1;
    }
    if (s == 'DRIVER_ASSIGNED' || s == 'DRIVER_PICKED_UP' || s == 'PICKED_UP') {
      return 2;
    }
    return 0; // PLACED or other initial state
  }
}
