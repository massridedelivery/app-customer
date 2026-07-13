import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/data/datasources/account_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles PDPA-related actions: data export, consent, and account deletion.
class PrivacyPdpaScreen extends ConsumerWidget {
  const PrivacyPdpaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: Text('ความเป็นส่วนตัว PDPA', style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.foundationBlue100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.foundationBlue200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สิทธิ์ตาม PDPA',
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คุณมีสิทธิ์จัดการข้อมูลส่วนบุคคลของคุณตามพระราชบัญญัติ PDPA',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('การจัดการข้อมูล', style: AppTypography.heading4),
          const SizedBox(height: 14),
          _PdpaTile(
            icon: Icons.download_rounded,
            iconColor: AppColors.primary,
            title: 'ส่งออกข้อมูลของฉัน',
            subtitle: 'ดาวน์โหลดข้อมูลส่วนบุคคลทั้งหมดในรูปแบบ JSON',
            onTap: () => _exportData(context, ref),
          ),
          const SizedBox(height: 12),
          _PdpaTile(
            icon: Icons.history_edu_rounded,
            iconColor: AppColors.primary,
            title: 'ประวัติความยินยอม',
            subtitle: 'ดูและจัดการความยินยอมของคุณ',
            onTap: () => _showConsentDialog(context, ref),
          ),
          const SizedBox(height: 32),
          Text(
            'อันตราย',
            style: AppTypography.heading4.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 14),
          _PdpaTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.error,
            title: 'ยื่นคำร้องลบบัญชี',
            subtitle: 'ส่งคำขอลบบัญชีและข้อมูลทั้งหมด (ไม่สามารถย้อนกลับได้)',
            onTap: () => _requestDeletion(context, ref),
            bgColor: AppColors.foundationRed100,
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        title: Text('กำลังส่งออกข้อมูล...'),
        content: Center(heightFactor: 1.5, child: CircularProgressIndicator()),
      ),
    );
    try {
      await ref.read(accountRemoteDataSourceProvider).exportData();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งออกข้อมูลสำเร็จ ตรวจสอบอีเมลของคุณ'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถส่งออกข้อมูลได้ในขณะนี้')),
        );
      }
    }
  }

  void _showConsentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ความยินยอม'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('นโยบายความเป็นส่วนตัว v2.1'),
            SizedBox(height: 4),
            Text('สถานะ: ยินยอมแล้ว ✓'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _requestDeletion(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยื่นคำร้องลบบัญชี'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุเหตุผลในการขอลบบัญชี'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'เหตุผล...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'ยื่นคำร้อง',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonCtrl.text.isNotEmpty) {
      try {
        await ref
            .read(accountRemoteDataSourceProvider)
            .requestDeletion(reasonCtrl.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('รับคำร้องแล้ว ทีมงานจะดำเนินการภายใน 30 วัน'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถยื่นคำร้องได้ในขณะนี้')),
          );
        }
      }
    }
  }
}

class _PdpaTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? bgColor;

  const _PdpaTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.foundationGrayscale200),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCFD1D9)),
          ],
        ),
      ),
    );
  }
}
