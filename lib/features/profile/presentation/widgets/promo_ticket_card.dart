import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/widgets/coupon_card.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Width of the service stub on the left of a [PromoTicketCard].
const double kPromoStubWidth = 84;

/// Radius of the notches punched at the top and bottom of the perforation.
const double _notch = 8;

/// The look of a [PromoScope]'s stub: solid color, the darker text color used
/// for the card's link, icon and name.
extension PromoStubStyle on PromoScope {
  Color get stubColor => switch (this) {
    PromoScope.ride => const Color(0xFFC8323F),
    PromoScope.food => const Color(0xFFE2855A),
    PromoScope.messenger => const Color(0xFF3E9361),
    PromoScope.all => const Color(0xFF4B4F5C),
  };

  Color get linkColor => switch (this) {
    PromoScope.ride => const Color(0xFFB4313F),
    PromoScope.food => const Color(0xFFB5561F),
    PromoScope.messenger => const Color(0xFF2E7D4F),
    PromoScope.all => const Color(0xFF3F414E),
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

/// A promo in "โปรโมชั่นของฉัน": a ticket with a solid stub naming the
/// service it's for (color, icon, name), notches top and bottom of a dashed
/// perforation, then the code, what it gives, the minimum and time left, and a
/// footer with the end date and "ดูรายละเอียด ›". The whole card opens the
/// promo.
class PromoTicketCard extends StatelessWidget {
  const PromoTicketCard({super.key, required this.data, this.onTap, this.now});

  final CouponCardData data;
  final VoidCallback? onTap;

  /// Clock for "เหลือ N วัน" (tests).
  final DateTime? now;

  /// "ลด 30% · สูงสุด ฿30" / "ลด ฿50" / "ส่งฟรี".
  String _headline(AppLocalizations l10n) {
    if (data.freeShipping) {
      final cap = data.maxDiscountText;
      return cap == null
          ? l10n.freeDelivery
          : '${l10n.freeDelivery} · ${l10n.promoMaxDiscount(cap)}';
    }
    final v = data.discountValue;
    if (v.isEmpty) return l10n.promotionTitle;
    final off = v.endsWith('%')
        ? l10n.promoHeadlinePercent(v.substring(0, v.length - 1))
        : l10n.promoHeadlineBaht(v.replaceFirst('฿', ''));
    final cap = data.maxDiscountText;
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
    const muted = Color(0xFF6B6E7A);

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.code.isNotEmpty ? data.code : (title ?? headline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1D22),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            // The admin's title says it best; else what the code gives.
            data.code.isNotEmpty && title != null && title.isNotEmpty
                ? title
                : headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1B1D22)),
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: minText),
                if (left != null) ...[
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
            key: const Key('promoTicketMeta'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEFF2))),
            ),
            child: Row(
              // The link's unused share goes before it, so it sits right.
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
                          style: const TextStyle(fontSize: 11.5, color: muted),
                        ),
                ),
                const SizedBox(width: 8),
                // Never wraps: the date gives way first, and on a very
                // narrow phone the link shrinks rather than breaking.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.promoViewDetails,
                      key: const Key('promoTicketDetails'),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: scope.linkColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final stub = Container(
      width: kPromoStubWidth,
      color: scope.stubColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(scope.stubIcon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            scope.stubLabel(l10n),
            key: const Key('promoTicketStubLabel'),
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

    const shape = _TicketBorder(stubWidth: kPromoStubWidth);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: CustomPaint(
            foregroundPainter: const _PerforationPainter(
              x: kPromoStubWidth,
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

/// Rounded card with a semicircle notch cut into the top and bottom edges at
/// [stubWidth], and a hairline outline.
class _TicketBorder extends ShapeBorder {
  const _TicketBorder({required this.stubWidth});

  final double stubWidth;
  static const _radius = 14.0;
  static const _side = BorderSide(color: Color(0xFFE6E7EB));

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

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
      _path(rect.deflate(_side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _path(rect.deflate(_side.width / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _side.width
        ..color = _side.color,
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
