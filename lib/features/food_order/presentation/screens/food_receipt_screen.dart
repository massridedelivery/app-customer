import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_receipt_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoodReceiptScreen extends ConsumerWidget {
  final String orderId;

  const FoodReceiptScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodReceiptControllerProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => context.go('/main'),
        ),
        title: Text('ใบเสร็จ', style: AppTypography.heading4),
        centerTitle: true,
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, dynamic state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'เกิดข้อผิดพลาดในการโหลดใบเสร็จ: ${state.error}',
                textAlign: TextAlign.center,
                style: AppTypography.body1,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref
                    .read(foodReceiptControllerProvider(orderId).notifier)
                    .loadReceipt(orderId),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.order == null) {
      return const Center(child: Text('ไม่พบข้อมูลคำสั่งซื้อ'));
    }

    return _buildReceiptBody(context, state.order!);
  }

  Widget _buildReceiptBody(BuildContext context, FoodOrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.foundationGreen500,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'จัดส่งสำเร็จ',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ขอบคุณที่สั่งอาหารกับเรา',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Order items card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รายการอาหาร', style: AppTypography.heading4),
                const SizedBox(height: 16),
                ...order.items.map((item) {
                  final addon = item.selectedModifiers.map((e) => e.name).join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderItem(
                      name: item.name,
                      addon: addon.isNotEmpty ? addon : '-',
                      qty: item.quantity,
                      price: item.unitPrice,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Price breakdown card
          _buildCard(
            child: Column(
              children: [
                _buildPriceRow('ค่าอาหาร', _formatPrice(order.foodTotal)),
                const SizedBox(height: 10),
                _buildPriceRow(
                  'ค่าจัดส่ง',
                  order.deliveryFee == 0 ? 'ฟรี' : _formatPrice(order.deliveryFee),
                  valueColor: order.deliveryFee == 0 ? AppColors.foundationGreen600 : null,
                ),
                if (order.promoDiscount > 0) ...[
                  const SizedBox(height: 10),
                  _buildPriceRow(
                    'ส่วนลดคูปอง',
                    '- ${_formatPrice(order.promoDiscount)}',
                    valueColor: AppColors.foundationRed500,
                  ),
                ],
                const Divider(height: 24),
                _buildPriceRow(
                  'รวมทั้งหมด',
                  _formatPrice(order.totalAmount),
                  labelStyle: AppTypography.label1,
                  valueStyle: AppTypography.heading3.copyWith(
                    color: AppColors.foundationGreen600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment method card
          _buildCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ชำระเงินด้วย', style: AppTypography.caption4),
                    Text(
                      order.paymentMethod == 'CARD' ? 'บัตรเครดิต' : 'เงินสด',
                      style: AppTypography.label2,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _formatPrice(order.totalAmount),
                  style: AppTypography.label1.copyWith(
                    color: AppColors.semanticGrayNeutralFgHigh,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Order meta
          _buildCard(
            child: Column(
              children: [
                _buildMetaRow(
                  Icons.receipt_long,
                  'เลขที่คำสั่งซื้อ',
                  '#${order.id}',
                ),
                const Divider(height: 20),
                _buildMetaRow(
                  Icons.access_time,
                  'วันที่สั่งซื้อ',
                  ThaiDateFormatter.dateTime(order.placedAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/main'),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(
                    'กลับหน้าหลัก',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.foundationGreen600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: AppColors.foundationGreen500,
                    ),
                    foregroundColor: AppColors.foundationGreen600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/food-order/rating/$orderId'),
                  icon: const Icon(Icons.star_outline),
                  label: Text(
                    'ให้คะแนน',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticGrayNeutralBgWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.foundationGreen500,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOrderItem({
    required String name,
    required String addon,
    required int qty,
    required double price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The order item has no image field — neutral placeholder instead of
        // a hardcoded stock photo.
        Container(
          width: 64,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.restaurant, color: Colors.grey, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.label2),
              const SizedBox(height: 2),
              Text(
                addon,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatPrice(price), style: AppTypography.label2),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('x$qty', style: AppTypography.caption5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? AppTypography.body1),
        Text(
          value,
          style:
              valueStyle ??
              AppTypography.body1.copyWith(
                color: valueColor ?? AppColors.black,
              ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTypography.caption4,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return '฿${price.toInt()}';
    }
    return '฿${price.toStringAsFixed(2)}';
  }

}
