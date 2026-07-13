import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/controllers/sos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SOSScreen extends ConsumerWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sosHistoryProvider);
    final isTriggering = ref.watch(sosControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ความปลอดภัย SOS', style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency button
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onLongPress: isTriggering
                        ? null
                        : () => _confirmSOS(context, ref),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTriggering ? Colors.orange : AppColors.error,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: isTriggering
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sos_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'กดค้างเพื่อส่งสัญญาณฉุกเฉิน',
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.foundationRed100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.foundationRed300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ข้อมูลฉุกเฉิน',
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เมื่อกด SOS ระบบจะแจ้งเตือนผู้ดูแล, คนขับที่กำลังร่วมเดินทาง และข้อมูลจะถูกบันทึกไว้เพื่อความปลอดภัย',
                    style: AppTypography.body2.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('ประวัติ SOS', style: AppTypography.heading4),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Text('โหลดข้อมูลไม่สำเร็จ', style: AppTypography.body2),
              data: (history) => history.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E2E1)),
                      ),
                      child: Center(
                        child: Text(
                          'ไม่มีประวัติ SOS',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: history.map<Widget>((item) {
                        final s = item as Map<String, dynamic>;
                        final status = s['status'] ?? '';
                        final isResolved = status == 'RESOLVED';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5E2E1),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? AppColors.foundationGreen100
                                      : AppColors.foundationRed100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isResolved
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  color: isResolved
                                      ? AppColors.primary
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'เหตุการณ์ SOS',
                                      style: AppTypography.caption3,
                                    ),
                                    Text(
                                      _formatDate(s['created_at'] as String?),
                                      style: AppTypography.caption5.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? AppColors.foundationGreen100
                                      : AppColors.foundationRed100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isResolved ? 'แก้ไขแล้ว' : 'เปิดอยู่',
                                  style: AppTypography.caption5.copyWith(
                                    color: isResolved
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Safely extracts the `YYYY-MM-DD` portion of an ISO timestamp.
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.length < 10) return isoDate ?? '';
    return isoDate.substring(0, 10);
  }

  Future<void> _confirmSOS(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sos_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('ส่งสัญญาณ SOS', style: AppTypography.heading4),
          ],
        ),
        content: const Text(
          'ต้องการส่งสัญญาณฉุกเฉินใช่หรือไม่? ระบบจะแจ้งเตือนทีมงานทันที',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: AppTypography.label2),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('ส่ง SOS', style: AppTypography.label2),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(sosControllerProvider.notifier).triggerSos();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ส่งสัญญาณ SOS แล้ว ทีมงานได้รับแจ้งแล้ว'),
          backgroundColor: AppColors.error,
        ),
      );
      ref.invalidate(sosHistoryProvider);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่สามารถส่ง SOS ได้ในขณะนี้',
            style: AppTypography.caption4,
          ),
        ),
      );
    }
  }
}
