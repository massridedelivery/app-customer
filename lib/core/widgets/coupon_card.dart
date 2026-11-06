import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/core/utils/app_dates.dart';
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

  /// Promo title; null when the source has none (the card then shows the
  /// localized "โปรโมชั่น" / "Promotion").
  final String? title;
  final String description;

  /// Big value shown in the left ticket stub, e.g. "20%" or "฿50". Empty when
  /// the source has no numeric discount (then the stub shows an icon, unless
  /// [freeShipping]).
  final String discountValue;

  /// Free-shipping promo: the stub reads "ส่งฟรี" / "Free Delivery" (with no
  /// "ลด" prefix) instead of [discountValue].
  final bool freeShipping;

  /// Percentage cap shown under the value as "สูงสุด ฿100" / "Up to ฿100".
  /// Null when not applicable.
  final double? maxDiscount;

  final double minSpend;

  /// When the promo ends (from the API, UTC). Shown as "ใช้ถึง 31 ธ.ค. 2569" /
  /// "Valid until 31 Dec 2026" in Bangkok time. Null when absent/invalid.
  final DateTime? expiresAt;

  /// Ticket-stub color, by discount kind (see [promoColorOf]): fixed → red,
  /// percentage → orange, free shipping → green.
  final Color color;

  /// Which service the promo is for; shown as a text label. Null hides it.
  final PromoScope? scope;

  /// The customer's own points coupon (RW-…): labelled "คูปองแลกคะแนน".
  final bool isVoucher;

  const CouponCardData({
    required this.code,
    required this.title,
    required this.description,
    required this.discountValue,
    this.freeShipping = false,
    this.maxDiscount,
    this.minSpend = 0,
    this.expiresAt,
    this.color = AppColors.primary,
    this.scope,
    this.isVoucher = false,
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
      maxDiscount: (isPct && (p.maxDiscount ?? 0) > 0) ? p.maxDiscount : null,
      minSpend: p.minSpend,
      expiresAt: _expiry(p.validUntil),
      color: promoColorOf({'discount_type': p.discountType}),
      scope: PromoScope.fromAppliesTo(p.appliesTo),
      isVoucher: p.isVoucher,
    );
  }

  factory CouponCardData.fromMap(Map<String, dynamic> m) {
    // A points coupon (kind VOUCHER) carries `discount` as an object:
    // {type FIXED|PERCENT|FREE_DELIVERY, value, max_discount, min_spend}.
    final d = m['discount'] is Map
        ? Map<String, dynamic>.from(m['discount'] as Map)
        : null;
    final dType = (d?['type'] ?? '').toString().toUpperCase();
    final type = d != null
        ? (dType == 'PERCENT' ? 'percentage' : 'fixed')
        : (m['discount_type'] ?? '').toString().toLowerCase();
    final val = _num(d?['value'] ?? m['discount_value'] ?? m['discount']);
    final isPct = type == 'percentage';
    final maxV = _num(d?['max_discount'] ?? m['max_discount']);
    // Free shipping is a 100% discount on delivery in the pricing engine, so
    // key it off `promo_type` and show "ส่งฟรี" instead of "ลด 100%".
    final isFreeShip =
        dType == 'FREE_DELIVERY' ||
        (m['promo_type'] ?? '').toString().toLowerCase() == 'free_shipping';
    final isVoucher = (m['kind'] ?? '').toString().toUpperCase() == 'VOUCHER';
    return CouponCardData(
      code: (m['code'] ?? '').toString(),
      title: (m['title'] ?? m['name'])?.toString(),
      description: (m['description'] ?? m['discount_text'] ?? '').toString(),
      discountValue: isFreeShip
          ? ''
          : (val <= 0 ? '' : (isPct ? '${_fmt(val)}%' : '฿${_fmt(val)}')),
      freeShipping: isFreeShip,
      maxDiscount: (!isFreeShip && isPct && maxV > 0) ? maxV : null,
      minSpend: _num(m['min_order'] ?? m['min_spend'] ?? d?['min_spend']),
      expiresAt: _expiry(
        (m['valid_until'] ?? m['expires_at'] ?? '').toString(),
      ),
      color: isFreeShip
          ? promoColorOf({'promo_type': 'free_shipping'})
          : promoColorOf(d == null ? m : {'discount_type': type}),
      scope: promoScopeOf(m),
      isVoucher: isVoucher,
    );
  }

  /// Food checkout promos come pre-scoped to food and only carry a flat baht
  /// `discount` (no discount type).
  factory CouponCardData.fromFoodPromo(PromoModel p) {
    return CouponCardData(
      code: p.code,
      title: p.title,
      description: p.description.isNotEmpty
          ? p.description
          : (p.discountText ?? ''),
      discountValue: p.discount <= 0 ? '' : '฿${_fmt(p.discount)}',
      minSpend: p.minOrder,
      expiresAt: _expiry(p.expiresAt),
      color: p.color != null ? Color(p.color!) : AppColors.primary,
      scope: PromoScope.food,
      isVoucher: p.isVoucher,
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static String _fmt(double v) => v.toStringAsFixed(0);

  /// [maxDiscount] formatted for display ("100"), or null.
  String? get maxDiscountText =>
      maxDiscount == null ? null : _fmt(maxDiscount!);

  static DateTime? _expiry(String raw) =>
      raw.trim().isEmpty ? null : DateTime.tryParse(raw);
}

/// Width of the service stub on the left of a [CouponCard].
const double kCouponStubWidth = 84;

/// Radius of the notches punched at the top and bottom of the perforation.
const double _notch = 8;

/// The look of a [PromoScope]'s stub: solid colour, the darker colour used for
/// the card's link, its icon and name.
extension PromoStubStyle on PromoScope {
  Color get stubColor => switch (this) {
    PromoScope.ride => const Color(0xFFC8323F),
    PromoScope.food => const Color(0xFFE2855A),
    PromoScope.messenger => const Color(0xFF2F6FD6),
    PromoScope.all => const Color(0xFFC8323F),
  };

  Color get linkColor => switch (this) {
    PromoScope.ride => const Color(0xFFB4313F),
    PromoScope.food => const Color(0xFFB5561F),
    PromoScope.messenger => const Color(0xFF1F55B0),
    PromoScope.all => const Color(0xFFB4313F),
  };

  IconData get stubIcon => switch (this) {
    PromoScope.ride => Icons.two_wheeler_rounded,
    PromoScope.food => Icons.restaurant_rounded,
    PromoScope.messenger => Icons.inventory_2_outlined,
    PromoScope.all => Icons.local_offer_outlined,
  };

  String stubLabel(AppLocalizations l10n) => switch (this) {
    PromoScope.ride => l10n.promoStubRide,
    PromoScope.food => l10n.promoStubFood,
    PromoScope.messenger => l10n.promoStubParcel,
    PromoScope.all => l10n.promoStubAll,
  };
}

/// Free delivery has a stub of its own (whatever its scope): teal, a
/// delivery icon and "ส่งฟรี".
const Color kFreeDeliveryStubColor = Color(0xFF13A08F);
const Color kFreeDeliveryLinkColor = Color(0xFF0B7568);

/// "เหลือ 3 วัน" / "เหลือ 5 ชม." once a promo ends within 7 days; null
/// otherwise (or when it has no end, or has already ended).
String? promoTimeLeft(
  DateTime? expiresAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  if (expiresAt == null) return null;
  final left = expiresAt.difference((now ?? DateTime.now()).toUtc());
  if (left.isNegative || left > const Duration(days: 7)) return null;
  if (left >= const Duration(days: 1)) {
    return l10n.promoLeftDays('${left.inDays}');
  }
  final hours = left.inHours < 1 ? 1 : left.inHours;
  return l10n.promoLeftHours('$hours');
}

/// The one promo / coupon card of the app, used by every list of them — the
/// "โปรโมชั่นของฉัน" list, the ride / parcel / food coupon pickers and
/// "คูปองของฉัน" — so a promo looks the same wherever it appears.
///
/// A ticket: a solid stub naming the service it's for (colour, icon, name),
/// notches top and bottom of a dashed perforation, then the code (with
/// "คูปองแลกคะแนน" on a points coupon), what it gives, the minimum and the
/// time left, and a footer with the end date and the action.
///
/// The action:
/// - browse: pass [onTap] and leave [onApply] null — the whole card opens the
///   promo and the action is a "ดูรายละเอียด ›" link.
/// - picker: [onApply] / [onCancel] drive an apply / cancel toggle.
/// - anything else: [action] replaces it (e.g. "ใช้เลย" on a voucher).
class CouponCard extends StatelessWidget {
  final CouponCardData data;
  final bool isSelected;
  final VoidCallback? onApply;
  final VoidCallback? onCancel;

  /// Apply-button label; defaults to the localized "ใช้คูปอง" / "Use".
  final String? applyLabel;

  /// Browse mode: tapping the card (e.g. opening the promo detail).
  final VoidCallback? onTap;

  /// False greys the card out and disables applying (e.g. a food promo whose
  /// minimum order isn't met yet, or a used coupon).
  final bool isEnabled;

  /// Optional extra row under the card body (e.g. "order ฿X more").
  final Widget? footer;

  /// Replaces the footer's action.
  final Widget? action;

  /// Clock for "เหลือ N วัน" (tests).
  final DateTime? now;

  const CouponCard({
    super.key,
    required this.data,
    this.isSelected = false,
    this.onApply,
    this.onCancel,
    this.applyLabel,
    this.onTap,
    this.isEnabled = true,
    this.footer,
    this.action,
    this.now,
  });

  bool get _browse => onApply == null && action == null;

  /// "ลด 30% · สูงสุด ฿30" / "ลด ฿50" / "ส่งฟรี".
  String _headline(AppLocalizations l10n) {
    final cap = data.maxDiscountText;
    if (data.freeShipping) {
      return cap == null
          ? l10n.freeDelivery
          : '${l10n.freeDelivery} · ${l10n.promoMaxDiscount(cap)}';
    }
    final v = data.discountValue;
    if (v.isEmpty) {
      return data.description.isNotEmpty
          ? data.description
          : l10n.promotionTitle;
    }
    final off = v.endsWith('%')
        ? l10n.promoHeadlinePercent(v.substring(0, v.length - 1))
        : l10n.promoHeadlineBaht(v.replaceFirst('฿', ''));
    return cap == null ? off : '$off · ${l10n.promoMaxDiscount(cap)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = data.scope ?? PromoScope.all;
    final title = data.title?.trim();
    final headline = _headline(l10n);
    final left = promoTimeLeft(data.expiresAt, l10n, now: now);
    final minText = data.minSpend > 0
        ? l10n.promoMinSpend(data.minSpend.toStringAsFixed(0))
        : l10n.promoNoMinSpend;
    final muted = isEnabled ? const Color(0xFF6B6E7A) : Colors.grey.shade400;
    final ink = isEnabled ? const Color(0xFF1B1D22) : Colors.grey.shade500;
    final free = data.freeShipping;
    final stubColor = free ? kFreeDeliveryStubColor : scope.stubColor;
    final linkColor = !isEnabled
        ? Colors.grey.shade500
        : (free ? kFreeDeliveryLinkColor : scope.linkColor);
    final codeLine = data.code.isNotEmpty ? data.code : (title ?? headline);
    final secondLine = data.code.isNotEmpty && title != null && title.isNotEmpty
        ? title
        : headline;

    final Widget trailing =
        action ??
        (_browse
            ? Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.promoViewDetails,
                    key: const Key('couponDetails'),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: linkColor,
                    ),
                  ),
                ),
              )
            : PromoApplyButton(
                isSelected: isSelected,
                isEnabled: isEnabled,
                onApply: onApply!,
                onCancel: onCancel ?? () {},
                applyLabel: applyLabel ?? l10n.promoUseCoupon,
              ));

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  codeLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (data.isVoucher) ...[
                const SizedBox(width: 6),
                const _VoucherLabel(),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            secondLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: ink),
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: minText),
                if (left != null && isEnabled) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: left,
                    style: const TextStyle(
                      color: Color(0xFFB5651D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            key: const Key('couponMeta'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEFF2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: data.expiresAt == null
                      ? const SizedBox.shrink()
                      : Text(
                          l10n.couponValidUntil(
                            AppDates.of(
                              context,
                            ).date(AppDates.bangkok(data.expiresAt!)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                ),
                const SizedBox(width: 8),
                // Never wraps: the date gives way first, and on a very
                // narrow phone the link shrinks rather than breaking.
                trailing,
              ],
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );

    final stub = Container(
      width: kCouponStubWidth,
      color: isEnabled ? stubColor : Colors.grey.shade400,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            free ? Icons.delivery_dining_rounded : scope.stubIcon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            free ? l10n.freeDelivery : scope.stubLabel(l10n),
            key: const Key('couponStubLabel'),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    final shape = _TicketBorder(
      stubWidth: kCouponStubWidth,
      side: isSelected
          ? BorderSide(color: AppColors.primary.withAlpha(150), width: 1.5)
          : const BorderSide(color: Color(0xFFE6E7EB)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? const Color(0xFFFFF7F7) : Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: _browse ? onTap : null,
          child: CustomPaint(
            foregroundPainter: const _PerforationPainter(
              x: kCouponStubWidth,
              inset: _notch + 3,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stub,
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "คูปองแลกคะแนน" on the customer's own points coupon.
class _VoucherLabel extends StatelessWidget {
  const _VoucherLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('couponVoucherLabel'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppLocalizations.of(context)!.promoVoucherLabel,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF8A5A00),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Rounded card with a semicircle notch cut into the top and bottom edges at
/// [stubWidth], outlined with [side].
class _TicketBorder extends ShapeBorder {
  const _TicketBorder({required this.stubWidth, required this.side});

  final double stubWidth;
  final BorderSide side;
  static const _radius = 14.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect r) {
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(_radius)));
    final notches = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + stubWidth, r.top),
          radius: _notch,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + stubWidth, r.bottom),
          radius: _notch,
        ),
      );
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _path(rect.deflate(side.width / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// Dashed vertical line at [x], between the two notches.
class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.x, required this.inset});

  final double x;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDADCE1)
      ..strokeWidth = 1.5;
    const dash = 4.0, gap = 3.5;
    var y = inset;
    while (y < size.height - inset) {
      canvas.drawLine(
        Offset(x + 0.75, y),
        Offset(x + 0.75, (y + dash).clamp(0, size.height - inset)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter old) =>
      old.x != x || old.inset != inset;
}

/// Manual coupon-code entry row (pill field + apply button + inline error),
/// shared by the ride "ใช้คูปอง" and messenger "เลือกโค้ดส่วนลด" screens so the
/// manual-entry UX is identical.
class CouponManualEntry extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onApply;

  /// Defaults to the localized "ใช้งาน" / "Apply".
  final String? applyLabel;

  /// Defaults to the localized "กรอกรหัสคูปองด้วยตนเอง" / "Enter a coupon code".
  final String? hint;
  final String? errorText;
  final bool isLoading;
  final VoidCallback? onChanged;

  const CouponManualEntry({
    super.key,
    required this.controller,
    required this.onApply,
    this.applyLabel,
    this.hint,
    this.errorText,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      hintText: hint ?? l10n.promoEnterCodeHint,
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
                            applyLabel ?? l10n.promoApply,
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
