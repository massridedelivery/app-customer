import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coupon picker for the messenger booking. Lets the user either type a code or
/// tap one from their active promotions (GET /api/customer/promo/list). Returns
/// the chosen code string via `Navigator.pop`, or null if dismissed.
class MessengerCouponScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const MessengerCouponScreen({super.key, this.initialCode});

  @override
  ConsumerState<MessengerCouponScreen> createState() =>
      _MessengerCouponScreenState();
}

class _MessengerCouponScreenState extends ConsumerState<MessengerCouponScreen> {
  late final TextEditingController _manual = TextEditingController(
    text: widget.initialCode ?? '',
  );

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promoListProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'เลือกโค้ดส่วนลด',
          style: AppTypography.heading4.copyWith(color: AppColors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Manual entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'กรอกโค้ดส่วนลด',
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.foundationGrayscale300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onSubmitted: _apply,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _apply(_manual.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ใช้โค้ด'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: promosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'โหลดโค้ดส่วนลดไม่สำเร็จ',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
              ),
              data: (raw) {
                final promos = raw
                    .map(
                      (e) => e is Map<String, dynamic>
                          ? e
                          : Map<String, dynamic>.from(e as Map),
                    )
                    .toList();
                if (promos.isEmpty) {
                  return Center(
                    child: Text(
                      'ยังไม่มีโค้ดส่วนลด',
                      style: AppTypography.label2.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: promos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) => _CouponTile(
                    promo: promos[i],
                    onTap: (code) => _apply(code),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final Map<String, dynamic> promo;
  final ValueChanged<String> onTap;
  const _CouponTile({required this.promo, required this.onTap});

  String get _title =>
      (promo['title'] ?? promo['name'] ?? 'โปรโมชั่น').toString();
  String get _code => (promo['code'] ?? '').toString();
  num get _minSpend {
    final v = promo['min_order'] ?? promo['min_spend'] ?? 0;
    return v is num ? v : num.tryParse(v.toString()) ?? 0;
  }

  String get _headline {
    final type = (promo['discount_type'] ?? '').toString().toLowerCase();
    final rawVal = promo['discount_value'] ?? promo['discount'] ?? 0;
    final num value = rawVal is num
        ? rawVal
        : num.tryParse(rawVal.toString()) ?? 0;
    if (value <= 0) return _title;
    if (type == 'percentage') return 'ลด ${value.toStringAsFixed(0)}%';
    return 'ลด ฿${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _code.isEmpty ? null : () => onTap(_code),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.foundationGrayscale200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.foundationRed100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer,
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
                    _headline,
                    style: AppTypography.label1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (_code.isNotEmpty) _code,
                      if (_minSpend > 0) 'ขั้นต่ำ ฿${_minSpend.toStringAsFixed(0)}',
                    ].join('  •  '),
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'ใช้โค้ด',
              style: AppTypography.label2.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
