import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/promo_card.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:flutter/material.dart';

/// Normalized data a [CouponCard] renders, adapted from each feature's own
/// coupon shape (ride's typed [RidePromo], messenger/profile's raw JSON maps).
class CouponCardData {
  final String code;
  final String title;
  final String description;

  /// Big value shown in the left ticket stub, e.g. "20%" or "฿50". Empty when
  /// the source has no numeric discount (then the stub shows an icon).
  final String discountValue;

  /// Secondary discount line, e.g. "สูงสุด ฿100". Null when not applicable.
  final String? subDiscount;

  final double minSpend;

  /// e.g. "ใช้ถึง 31/12/68". Null when there's no/invalid expiry.
  final String? expiryLabel;

  /// Ticket-stub color, by discount kind (see [promoColorOf]): fixed → red,
  /// percentage → orange, free shipping → green.
  final Color color;

  /// Small line above [discountValue] in the stub — "ลด", or empty for
  /// "ส่งฟรี" which reads on its own.
  final String stubPrefix;

  /// Which service the promo is for; shown as a text label. Null hides it.
  final PromoScope? scope;

  const CouponCardData({
    required this.code,
    required this.title,
    required this.description,
    required this.discountValue,
    this.subDiscount,
    this.minSpend = 0,
    this.expiryLabel,
    this.color = AppColors.primary,
    this.stubPrefix = 'ลด',
    this.scope,
  });

  factory CouponCardData.fromRidePromo(RidePromo p) {
    final isPct = p.discountType.toLowerCase() == 'percentage';
    return CouponCardData(
      code: p.code,
      title: p.name,
      description: p.description,
      discountValue: p.discountValue <= 0
          ? ''
          : (isPct ? '${_fmt(p.discountValue)}%' : '฿${_fmt(p.discountValue)}'),
      subDiscount: (isPct && (p.maxDiscount ?? 0) > 0)
          ? 'สูงสุด ฿${_fmt(p.maxDiscount!)}'
          : null,
      minSpend: p.minSpend,
      expiryLabel: _expiry(p.validUntil),
      color: promoColorOf({'discount_type': p.discountType}),
      scope: PromoScope.fromAppliesTo(p.appliesTo),
    );
  }

  factory CouponCardData.fromMap(Map<String, dynamic> m) {
    final type = (m['discount_type'] ?? '').toString().toLowerCase();
    final val = _num(m['discount_value'] ?? m['discount']);
    final isPct = type == 'percentage';
    final maxV = _num(m['max_discount']);
    // Free shipping is a 100% discount on delivery in the pricing engine, so
    // key it off `promo_type` and show "ส่งฟรี" instead of "ลด 100%".
    final isFreeShip =
        (m['promo_type'] ?? '').toString().toLowerCase() == 'free_shipping';
    return CouponCardData(
      code: (m['code'] ?? '').toString(),
      title: (m['title'] ?? m['name'] ?? 'โปรโมชั่น').toString(),
      description: (m['description'] ?? '').toString(),
      discountValue: isFreeShip
          ? 'ส่งฟรี'
          : (val <= 0 ? '' : (isPct ? '${_fmt(val)}%' : '฿${_fmt(val)}')),
      subDiscount:
          (!isFreeShip && isPct && maxV > 0) ? 'สูงสุด ฿${_fmt(maxV)}' : null,
      minSpend: _num(m['min_order'] ?? m['min_spend']),
      expiryLabel:
          _expiry((m['valid_until'] ?? m['expires_at'] ?? '').toString()),
      color: promoColorOf(m),
      stubPrefix: isFreeShip ? '' : 'ลด',
      scope: promoScopeOf(m),
    );
  }

  /// Food checkout promos come pre-scoped to food and only carry a flat baht
  /// `discount` (no discount type).
  factory CouponCardData.fromFoodPromo(PromoModel p) {
    return CouponCardData(
      code: p.code,
      title: p.title,
      description: p.description,
      discountValue: p.discount <= 0 ? '' : '฿${_fmt(p.discount)}',
      minSpend: p.minOrder,
      expiryLabel: _expiry(p.expiresAt),
      color: p.color != null ? Color(p.color!) : AppColors.primary,
      scope: PromoScope.food,
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static String _fmt(double v) => v.toStringAsFixed(0);

  static String? _expiry(String raw) {
    if (raw.trim().isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    final yy = ((d.year + 543) % 100).toString().padLeft(2, '0');
    return 'ใช้ถึง ${d.day}/${d.month}/$yy';
  }
}

/// Ticket-style promo card used everywhere a promo is listed — the
/// "โปรโมชั่นของฉัน" list and the ride / messenger / food coupon pickers — so a
/// promo looks the same wherever it appears: a value stub on the left colored by
/// discount kind, a dashed perforation, then the code, a service-scope label,
/// details and the trailing action.
///
/// Two modes:
/// - picker (default): [onApply] / [onCancel] drive an apply-cancel toggle.
/// - browse: pass [onTap] and leave [onApply] null — the whole card opens the
///   promo and the action becomes a "ดูรายละเอียด" link.
class CouponCard extends StatelessWidget {
  final CouponCardData data;
  final bool isSelected;
  final VoidCallback? onApply;
  final VoidCallback? onCancel;
  final String applyLabel;

  /// Browse mode: tapping the card (e.g. opening the promo detail).
  final VoidCallback? onTap;

  /// False greys the card out and disables applying (e.g. a food promo whose
  /// minimum order isn't met yet).
  final bool isEnabled;

  /// Optional extra row under the card body (e.g. "order ฿X more").
  final Widget? footer;

  const CouponCard({
    super.key,
    required this.data,
    this.isSelected = false,
    this.onApply,
    this.onCancel,
    this.applyLabel = 'ใช้คูปอง',
    this.onTap,
    this.isEnabled = true,
    this.footer,
  });

  bool get _browse => onApply == null;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();
    if (!_browse || onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withAlpha(150)
              : const Color(0xFFEDEDED),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withAlpha(22)
                : Colors.black.withAlpha(8),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ValueStub(data: data, enabled: isEnabled),
              const _DashedDivider(),
              Expanded(
                child: Padding(
                  // Compact: ~30% shorter than before — the action shares the
                  // expiry row and the description is a single line.
                  padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.code.isEmpty ? data.title : data.code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isEnabled
                                    ? Colors.black87
                                    : Colors.grey[500],
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data.scope != null) ...[
                            const SizedBox(width: 6),
                            _ScopeLabel(scope: data.scope!),
                          ],
                        ],
                      ),
                      if (data.code.isNotEmpty && data.title.isNotEmpty)
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (data.description.isNotEmpty)
                        Text(
                          data.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (data.minSpend > 0) ...[
                            _Chip(
                              'ขั้นต่ำ ฿${data.minSpend.toStringAsFixed(0)}',
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: data.expiryLabel == null
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 11,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          data.expiryLabel!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 6),
                          _browse
                              ? Text(
                                  'ดูรายละเอียด ›',
                                  style: AppTypography.caption5.copyWith(
                                    color: data.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : PromoApplyButton(
                                  isSelected: isSelected,
                                  isEnabled: isEnabled,
                                  onApply: onApply!,
                                  onCancel: onCancel ?? () {},
                                  applyLabel: applyLabel,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Text-only service-scope label, e.g. "เฉพาะเรียกรถ".
class _ScopeLabel extends StatelessWidget {
  final PromoScope scope;
  const _ScopeLabel({required this.scope});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: scope.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        scope.label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 9,
          color: scope.foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ValueStub extends StatelessWidget {
  final CouponCardData data;
  final bool enabled;
  const _ValueStub({required this.data, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final base = enabled ? data.color : Colors.grey.shade400;
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.black, 0.25)!, base],
        ),
      ),
      child: Center(
        child: data.discountValue.isEmpty
            ? const Icon(
                Icons.confirmation_number_rounded,
                color: Colors.white,
                size: 34,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.stubPrefix.isNotEmpty)
                    Text(
                      data.stubPrefix,
                      style: AppTypography.caption5.copyWith(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  Text(
                    data.discountValue,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: data.discountValue.length > 4 ? 14 : 18,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  if (data.subDiscount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subDiscount!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFFFF8F00),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Vertical dashed perforation between the value stub and the details.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(1, double.infinity),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    const dash = 4.0, gap = 4.0;
    double y = 6;
    while (y < size.height - 6) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Manual coupon-code entry row (pill field + apply button + inline error),
/// shared by the ride "ใช้คูปอง" and messenger "เลือกโค้ดส่วนลด" screens so the
/// manual-entry UX is identical.
class CouponManualEntry extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onApply;
  final String applyLabel;
  final String hint;
  final String? errorText;
  final bool isLoading;
  final VoidCallback? onChanged;

  const CouponManualEntry({
    super.key,
    required this.controller,
    required this.onApply,
    this.applyLabel = 'ใช้งาน',
    this.hint = 'กรอกรหัสคูปองด้วยตนเอง',
    this.errorText,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? AppColors.error : const Color(0xFFDDDDDD),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.local_offer_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => onChanged?.call(),
                    onSubmitted: (v) => onApply(v.trim()),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => onApply(controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      minimumSize: const Size(0, 40),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            applyLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                errorText!,
                style: AppTypography.caption5.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
