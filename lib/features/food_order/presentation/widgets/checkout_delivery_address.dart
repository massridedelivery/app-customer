import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutDeliveryAddress extends ConsumerWidget {
  const CheckoutDeliveryAddress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final checkoutState = ref.watch(checkoutProvider);

    final addressDisplay = homeState.foodAddress ?? 'โปรดเลือกสถานที่';
    final addressSubDisplay =
        homeState.foodLocation != null
            ? '${homeState.foodLocation!.latitude.toStringAsFixed(4)}, ${homeState.foodLocation!.longitude.toStringAsFixed(4)}'
            : 'แตะเพื่อเลือกจุดส่งบนแผนที่';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              context.push('/food-place-search');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addressDisplay, style: AppTypography.label2),
                      Text(
                        addressSubDisplay,
                        style: AppTypography.caption4.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showFloorUnitBottomSheet(context, ref, checkoutState.floorUnit),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    checkoutState.floorUnit.isEmpty ? 'ชั้น / เลขที่' : checkoutState.floorUnit,
                    style: AppTypography.body1.copyWith(
                      color: checkoutState.floorUnit.isEmpty ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (checkoutState.floorUnit.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ระบุเพื่อการจัดส่งที่ราบรื่น',
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    checkoutState.floorUnit.isEmpty ? 'เพิ่ม' : 'แก้ไข',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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

  void _showFloorUnitBottomSheet(BuildContext context, WidgetRef ref, String currentFloorUnit) {
    final controller = TextEditingController(text: currentFloorUnit);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ระบุ ชั้น / เลขที่', style: AppTypography.label1),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'เช่น ชั้น 5 ห้อง 502',
                hintStyle: AppTypography.caption4,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(checkoutProvider.notifier).updateFloorUnit(controller.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('บันทึก', style: AppTypography.label2),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
