import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';

class LiveFoodTrackingRider extends ConsumerWidget {
  final String orderId;

  const LiveFoodTrackingRider({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.order),
    );
    final driverName = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.driverName),
    );
    final vehiclePlate = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.vehiclePlate),
    );

    final resolvedDriverName = order?.driverInfo?.fullName ?? driverName ?? 'กำลังค้นหาคนขับ';
    final resolvedVehiclePlate = order?.driverInfo?.vehiclePlate ?? vehiclePlate;
    final rating = order?.driverInfo?.rating != null 
        ? order!.driverInfo!.rating!.toStringAsFixed(1)
        : '5.0';

    final vehicleDetails = [
      if (resolvedVehiclePlate != null && resolvedVehiclePlate.isNotEmpty) resolvedVehiclePlate,
      if (order?.driverInfo?.vehicleModel != null && order!.driverInfo!.vehicleModel!.isNotEmpty)
        order.driverInfo!.vehicleModel,
      if (order?.driverInfo?.vehicleColor != null && order!.driverInfo!.vehicleColor!.isNotEmpty)
        order.driverInfo!.vehicleColor,
    ].join(' • ');

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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.foundationGreen100,
                child: const Icon(
                  Icons.sports_motorsports,
                  color: AppColors.foundationGreen600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedDriverName,
                      style: AppTypography.label2,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        if (vehicleDetails.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vehicleDetails,
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.semanticGrayNeutralFgLowOnWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/food-order/chat/$orderId'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foundationGreen600,
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final phone = order?.driverInfo?.phone;
                    if (phone != null && phone.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('เบอร์โทรศัพท์คนขับ'),
                          content: SelectableText(phone),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ปิด'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่มีเบอร์โทรศัพท์คนขับสำหรับออเดอร์นี้'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foundationGreen600,
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
