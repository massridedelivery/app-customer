import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';
import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/presentation/widgets/resume_empty_state.dart';
import 'package:customer_app/features/food_order/presentation/widgets/resume_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResumeFoodOrderScreen extends ConsumerStatefulWidget {
  const ResumeFoodOrderScreen({super.key});

  @override
  ConsumerState<ResumeFoodOrderScreen> createState() => _ResumeFoodOrderScreenState();
}

class _ResumeFoodOrderScreenState extends ConsumerState<ResumeFoodOrderScreen> {
  bool _isCancelling = false;

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกคำสั่งซื้อ', style: AppTypography.heading4),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการยกเลิกคำสั่งซื้อนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ไม่ใช่', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ใช่, ยกเลิกเลย', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      await repo.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกคำสั่งซื้อสำเร็จ'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(activeOrdersControllerProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถยกเลิกคำสั่งซื้อได้: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(activeOrdersControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'ติดตามอาหาร',
          style: AppTypography.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        centerTitle: true,
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
            onPressed: () {
              ref.read(activeOrdersControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          activeOrdersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('เกิดข้อผิดพลาดในการโหลดข้อมูล', style: AppTypography.heading5),
                    const SizedBox(height: 8),
                    Text(err.toString(), style: AppTypography.caption4, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(activeOrdersControllerProvider.notifier).refresh(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('ลองใหม่', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) {
              // This screen tracks food only; ride has its own live screen
              final orders = items.where((i) => i.isFood).toList();
              if (orders.isEmpty) {
                return const ResumeEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(activeOrdersControllerProvider.notifier).refresh(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ResumeOrderCard(
                      order: order,
                      onCancel: _cancelOrder,
                    );
                  },
                ),
              );
            },
          ),
          if (_isCancelling)
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
}
