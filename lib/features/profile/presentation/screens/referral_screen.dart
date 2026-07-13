import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/data/datasources/referral_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final referralInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).getInfo();
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ชวนเพื่อน'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('โหลดข้อมูลไม่สำเร็จ', style: AppTypography.body2),
        ),
        data: (referral) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Hero illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.accentRedDeep],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group_add_rounded,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ชวนเพื่อนมาใช้ MASS',
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'รับ 100 แต้มทุกครั้งที่เพื่อนสมัครและใช้งาน',
                      style: AppTypography.body2.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Stats
              Row(
                children: [
                  _ReferralStat(
                    label: 'เพื่อนที่ชวนแล้ว',
                    value: '${referral['referral_count'] ?? 0}',
                    icon: Icons.people_rounded,
                  ),
                  const SizedBox(width: 12),
                  _ReferralStat(
                    label: 'แต้มที่ได้รับ',
                    value: '${referral['total_earned_points'] ?? 0}',
                    icon: Icons.stars_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Code section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E2E1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'โค้ดชวนเพื่อนของคุณ',
                      style: AppTypography.support1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.foundationBlue100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        referral['code'] ?? 'MASS-XXXX',
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: referral['code'] ?? ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('คัดลอกโค้ดแล้ว!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('คัดลอก'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('แชร์'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Apply referral
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E2E1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('มีโค้ดชวนเพื่อน?', style: AppTypography.heading4),
                    const SizedBox(height: 4),
                    Text(
                      'กรอกโค้ดที่เพื่อนส่งให้เพื่อรับโบนัสแต้ม',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ApplyReferralField(ref: ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReferralStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.heading3.copyWith(color: AppColors.primary),
            ),
            Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyReferralField extends StatefulWidget {
  final WidgetRef ref;
  const _ApplyReferralField({required this.ref});

  @override
  State<_ApplyReferralField> createState() => _ApplyReferralFieldState();
}

class _ApplyReferralFieldState extends State<_ApplyReferralField> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'เช่น MASS-XXXX',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _loading ? null : () => _applyCode(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('ใช้โค้ด'),
        ),
      ],
    );
  }

  Future<void> _applyCode(BuildContext context) async {
    if (_ctrl.text.isEmpty) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.ref
          .read(referralRemoteDataSourceProvider)
          .applyCode(_ctrl.text.trim());
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('ใช้โค้ดสำเร็จ! ได้รับโบนัสแต้มแล้ว')),
        );
        _ctrl.clear();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('โค้ดไม่ถูกต้องหรือเคยใช้แล้ว')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
