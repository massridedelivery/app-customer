import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/promo_card.dart';
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

  const CouponCardData({
    required this.code,
    required this.title,
    required this.description,
    required this.discountValue,
    this.subDiscount,
    this.minSpend = 0,
    this.expiryLabel,
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
    );
  }

  factory CouponCardData.fromMap(Map<String, dynamic> m) {
    final type = (m['discount_type'] ?? '').toString().toLowerCase();
    final val = _num(m['discount_value'] ?? m['discount']);
    final isPct = type == 'percentage';
    final maxV = _num(m['max_discount']);
    return CouponCardData(
      code: (m['code'] ?? '').toString(),
      title: (m['title'] ?? m['name'] ?? 'โปรโมชั่น').toString(),
      description: (m['description'] ?? '').toString(),
      discountValue:
          val <= 0 ? '' : (isPct ? '${_fmt(val)}%' : '฿${_fmt(val)}'),
      subDiscount:
          (isPct && maxV > 0) ? 'สูงสุด ฿${_fmt(maxV)}' : null,
      minSpend: _num(m['min_order'] ?? m['min_spend']),
      expiryLabel:
          _expiry((m['valid_until'] ?? m['expires_at'] ?? '').toString()),
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

/// Ticket-style coupon card shared by the ride & messenger coupon pickers: a
/// brand-red value stub on the left, a dashed perforation, then the code /
/// details and an apply-cancel toggle on the right.
class CouponCard extends StatelessWidget {
  final CouponCardData data;
  final bool isSelected;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final String applyLabel;

  const CouponCard({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onApply,
    required this.onCancel,
    this.applyLabel = 'ใช้คูปอง',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ValueStub(data: data),
              const _DashedDivider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.code.isEmpty ? data.title : data.code,
                        style: AppTypography.label1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data.code.isNotEmpty && data.title.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.title,
                          style: AppTypography.caption4.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (data.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.description,
                          style: AppTypography.caption5.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (data.minSpend > 0)
                            _Chip(
                              'ขั้นต่ำ ฿${data.minSpend.toStringAsFixed(0)}',
                            ),
                          if (data.expiryLabel != null) ...[
                            if (data.minSpend > 0) const SizedBox(width: 6),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      data.expiryLabel!,
                                      style: AppTypography.caption5.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PromoApplyButton(
                          isSelected: isSelected,
                          onApply: onApply,
                          onCancel: onCancel,
                          applyLabel: applyLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueStub extends StatelessWidget {
  final CouponCardData data;
  const _ValueStub({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentRedDeep, AppColors.primary],
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
                  Text(
                    'ลด',
                    style: AppTypography.caption5.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    data.discountValue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
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
