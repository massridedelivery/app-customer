import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/live_food_tracking_screen.dart';

class LiveFoodTrackingOrderSummary extends StatefulWidget {
  final OrderState currentState;

  const LiveFoodTrackingOrderSummary({
    super.key,
    required this.currentState,
  });

  @override
  State<LiveFoodTrackingOrderSummary> createState() => _LiveFoodTrackingOrderSummaryState();
}

class _LiveFoodTrackingOrderSummaryState extends State<LiveFoodTrackingOrderSummary> {
  bool _isOrderDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final order = ref.watch(
          liveFoodTrackingControllerProvider.select((s) => s.order),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('รายละเอียดคำสั่งซื้อ', style: AppTypography.label2),
                  if (widget.currentState != OrderState.finding)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isOrderDetailsExpanded = !_isOrderDetailsExpanded;
                        });
                      },
                      child: Text(
                        _isOrderDetailsExpanded ? 'ซ่อน' : 'แสดง',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.foundationGreen600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.currentState == OrderState.finding ||
                  _isOrderDetailsExpanded) ...[
                for (final item in order?.items ?? []) ...[
                  _buildOrderItem(
                    '${item.quantity}',
                    item.name,
                    item.selectedModifiers.map((e) => e.name).join(', '),
                    '฿${item.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
              _buildRow(
                'ค่าอาหาร',
                '฿${(order?.foodTotal ?? 0).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              _buildRow(
                'ค่าจัดส่ง',
                '฿${(order?.deliveryFee ?? 0).toStringAsFixed(0)}',
                valueColor: AppColors.semanticGrayNeutralFgHigh,
              ),
              if (order != null && order.promoDiscount > 0) ...[
                const SizedBox(height: 8),
                _buildRow(
                  'ส่วนลดส่วนตัว/โปรโมชั่น',
                  '-฿${order.promoDiscount.toStringAsFixed(0)}',
                  valueColor: Colors.red,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ยอดรวมทั้งหมด', style: AppTypography.label1),
                  Text(
                    '฿${(order?.totalAmount ?? 0).toStringAsFixed(0)}',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.foundationGreen600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption4.copyWith(
            color: valueColor ?? AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(
    String qty,
    String title,
    String subtitle,
    String price,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.foundationGreen100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${qty}x',
            style: AppTypography.caption4.copyWith(
              color: AppColors.foundationGreen700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.caption3),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(price, style: AppTypography.caption3),
      ],
    );
  }
}
