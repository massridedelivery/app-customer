import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A ticket: a [top] stub and a [bottom] part, with a real half-round bite
/// cut out of each side where they meet.
/// The bites are cut from the shape itself, so no edge line runs across them.
class AdvanceTicket extends StatelessWidget {
  const AdvanceTicket({
    super.key,
    required this.top,
    required this.bottom,
    this.topColor,
    this.topGradient,
  });

  final Widget top;
  final Widget bottom;
  final Color? topColor;
  final Gradient? topGradient;

  static const radius = 18.0;
  static const notch = 11.0;

  static const _shadow = [
    BoxShadow(color: Color(0x14141E1E), blurRadius: 14, offset: Offset(0, 6)),
  ];

  @override
  Widget build(BuildContext context) {
    const topShape = _TicketHalf(top: true);
    const bottomShape = _TicketHalf(
      top: false,
      outline: AppColors.foundationGrayscale300,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: topShape,
            color: topGradient == null ? topColor : null,
            gradient: topGradient,
            shadows: _shadow,
          ),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: topShape),
            child: top,
          ),
        ),
        DecoratedBox(
          decoration: const ShapeDecoration(
            shape: bottomShape,
            color: Colors.white,
            shadows: _shadow,
          ),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: bottomShape),
            child: bottom,
          ),
        ),
      ],
    );
  }
}

/// One half of the ticket: round outer corners, and a concave quarter-round
/// at each corner on the tear line so the two halves make a half-round bite.
class _TicketHalf extends ShapeBorder {
  const _TicketHalf({required this.top, this.outline});

  final bool top;

  /// A hairline round every edge but the tear line.
  final Color? outline;

  static const _r = AdvanceTicket.radius;
  static const _n = AdvanceTicket.notch;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    const round = Radius.circular(_r);
    const bite = Radius.circular(_n);
    final p = Path();
    if (top) {
      p
        ..moveTo(l, t + _r)
        ..arcToPoint(Offset(l + _r, t), radius: round)
        ..lineTo(r - _r, t)
        ..arcToPoint(Offset(r, t + _r), radius: round)
        ..lineTo(r, b - _n)
        ..arcToPoint(Offset(r - _n, b), radius: bite, clockwise: false)
        ..lineTo(l + _n, b)
        ..arcToPoint(Offset(l, b - _n), radius: bite, clockwise: false)
        ..close();
    } else {
      p
        ..moveTo(l, t + _n)
        ..arcToPoint(Offset(l + _n, t), radius: bite, clockwise: false)
        ..lineTo(r - _n, t)
        ..arcToPoint(Offset(r, t + _n), radius: bite, clockwise: false)
        ..lineTo(r, b - _r)
        ..arcToPoint(Offset(r - _r, b), radius: round)
        ..lineTo(l + _r, b)
        ..arcToPoint(Offset(l, b - _r), radius: round)
        ..close();
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final color = outline;
    if (color == null || top) return;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    const round = Radius.circular(_r);
    const bite = Radius.circular(_n);
    // Every edge but the straight tear line between the two bites.
    final p = Path()
      ..moveTo(r - _n, t)
      ..arcToPoint(Offset(r, t + _n), radius: bite, clockwise: false)
      ..lineTo(r, b - _r)
      ..arcToPoint(Offset(r - _r, b), radius: round)
      ..lineTo(l + _r, b)
      ..arcToPoint(Offset(l, b - _r), radius: round)
      ..lineTo(l, t + _n)
      ..arcToPoint(Offset(l + _n, t), radius: bite, clockwise: false);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
