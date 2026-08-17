import 'package:flutter/material.dart';

/// Wave-clipped bottom edge shared by the branded red hero headers (ride
/// landing + messenger booking), so the curve stays identical across screens.
class HeroWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..lineTo(0, h - 36)
      ..quadraticBezierTo(w * 0.25, h, w * 0.52, h - 16)
      ..quadraticBezierTo(w * 0.80, h - 40, w, h - 6)
      ..lineTo(w, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A very faint white delivery-motif pattern (scattered parcel / pin / vehicle
/// icons) meant to sit behind the content of a red gradient hero header. Adds a
/// little on-brand texture without hurting the readability of white text / the
/// search bar.
///
/// Returns a [Positioned.fill], so drop it in as the first child of a [Stack].
class HeroPatternOverlay extends StatelessWidget {
  const HeroPatternOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _HeroPatternPainter()),
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  /// Draws a single Material icon glyph centred at [at], rotated by [rot]
  /// radians, in white at [alpha] opacity.
  void _icon(
    Canvas canvas,
    IconData icon,
    Offset at,
    double sz,
    double alpha,
    double rot,
  ) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rot);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scattered delivery icons (parcel / truck / pin / scooter), biased to the
    // right and edges so they stay clear of the header's title on the left.
    _icon(canvas, Icons.inventory_2, Offset(w * 0.86, h * 0.30), 54, 0.08, -0.2);
    _icon(
      canvas,
      Icons.local_shipping,
      Offset(w * 0.60, h * 0.78),
      40,
      0.07,
      0.1,
    );
    _icon(canvas, Icons.location_on, Offset(w * 0.30, h * 0.30), 34, 0.07, 0.0);
    _icon(canvas, Icons.two_wheeler, Offset(w * 0.20, h * 0.82), 30, 0.06, 0.0);
    _icon(canvas, Icons.inventory_2, Offset(w * 0.48, h * 0.24), 22, 0.06, 0.25);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
