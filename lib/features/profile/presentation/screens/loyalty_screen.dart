import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/data/datasources/loyalty_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(loyaltySummaryProvider);
    final pointsAsync = ref.watch(_loyaltyPointsProvider);
    final cashbackAsync = ref.watch(_cashbackProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MASS Rewards'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('ไม่สามารถโหลดข้อมูลได้', style: AppTypography.body2),
        ),
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Tier card
              _TierCard(summary: summary),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _StatCard(
                    label: 'แต้มสะสม',
                    value: '${summary['points_balance'] ?? 0}',
                    icon: Icons.stars_rounded,
                    color: const Color(0xFFEB8C00),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'เงินคืน (฿)',
                    value:
                        '${(summary['cashback_balance'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Redeem button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRedeemDialog(
                    context,
                    ref,
                    summary['points_balance'] ?? 0,
                  ),
                  icon: const Icon(Icons.redeem),
                  label: const Text('แลกแต้ม'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Points transactions
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ประวัติแต้ม', style: AppTypography.heading4),
              ),
              const SizedBox(height: 12),
              pointsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
                data: (data) {
                  final txns = (data['transactions'] as List?) ?? [];
                  return Column(
                    children: txns
                        .map<Widget>(
                          (t) => _TransactionTile(
                            type: t['type'],
                            desc: t['description'],
                            points: t['points'],
                            date: t['created_at'],
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ประวัติเงินคืน', style: AppTypography.heading4),
              ),
              const SizedBox(height: 12),
              cashbackAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
                data: (list) => Column(
                  children: list
                      .map<Widget>(
                        (t) => _CashbackTile(item: t as Map<String, dynamic>),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, WidgetRef ref, int points) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แลกแต้ม'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('คุณมี $points แต้ม', style: AppTypography.body2),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนแต้มที่ต้องการแลก',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pts = int.tryParse(controller.text) ?? 0;
              if (pts > 0 && pts <= points) {
                try {
                  await ref.read(loyaltyRemoteDataSourceProvider).redeemPoints(pts);
                  ref.invalidate(loyaltySummaryProvider);
                  ref.invalidate(_loyaltyPointsProvider);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('แลกแต้มสำเร็จ!')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
            },
            child: const Text('แลก'),
          ),
        ],
      ),
    );
  }
}

// Additional providers scoped to this page
final loyaltySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(loyaltyRemoteDataSourceProvider).getSummary();
});

final _loyaltyPointsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(loyaltyRemoteDataSourceProvider).getPoints();
});

final _cashbackProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(loyaltyRemoteDataSourceProvider).getCashbackHistory();
});

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _TierCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tier = summary['tier'] ?? 'Bronze';
    final toNext = summary['points_to_next_tier'] ?? 1000;
    final points = summary['points_balance'] ?? 0;
    final nextTier = summary['next_tier'] ?? 'Silver';
    final progress = (points / (points + toNext)).clamp(0.0, 1.0);
    final cashbackPct = ((summary['cashback_rate'] ?? 0.0) * 100)
        .toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accentRedDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MASS REWARDS',
                    style: AppTypography.support1.copyWith(
                      color: Colors.white60,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary['tier_icon'] ?? ''} $tier',
                    style: AppTypography.heading3.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'คืน $cashbackPct%',
                  style: AppTypography.caption4.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$points แต้ม',
            style: AppTypography.heading2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ไปยังระดับ $nextTier',
                style: AppTypography.caption5.copyWith(color: Colors.white60),
              ),
              Text(
                'อีก $toNext แต้ม',
                style: AppTypography.caption5.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentRedVibrant,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.support1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(value, style: AppTypography.heading3.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String type;
  final String desc;
  final int points;
  final String date;
  const _TransactionTile({
    required this.type,
    required this.desc,
    required this.points,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isEarn = type == 'EARN';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarn
                  ? AppColors.foundationGreen100
                  : AppColors.foundationRed100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isEarn ? AppColors.primary : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: AppTypography.caption3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  date.substring(0, 10),
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? "+" : ""}$points',
            style: AppTypography.heading4.copyWith(
              color: isEarn ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashbackTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CashbackTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEarn = item['type'] == 'EARN';
    final amount = (item['amount'] as num).toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarn
                  ? AppColors.foundationMint100
                  : AppColors.foundationRed100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: isEarn ? AppColors.primary : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['description'], style: AppTypography.caption3),
                Text(
                  (item['created_at'] as String).substring(0, 10),
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? "+" : ""}฿$amount',
            style: AppTypography.heading4.copyWith(
              color: isEarn ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
