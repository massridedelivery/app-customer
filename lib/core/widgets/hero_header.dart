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

    // Scattered delivery icons (parcel / truck / pin / scooter), kept to the
    // UPPER-RIGHT band (w > 0.6, h < 0.6) so they never sit behind the title on
    // the left or the search bar / buttons along the bottom. Low opacity so they
    // read as faint texture rather than clutter over the controls.
    _icon(
      canvas,
      Icons.inventory_2,
      Offset(w * 0.86, h * 0.34),
      44,
      0.06,
      -0.15,
    );
    _icon(
      canvas,
      Icons.local_shipping,
      Offset(w * 0.62, h * 0.20),
      26,
      0.05,
      0.08,
    );
    _icon(canvas, Icons.location_on, Offset(w * 0.95, h * 0.60), 24, 0.05, 0.0);
    _icon(canvas, Icons.two_wheeler, Offset(w * 0.77, h * 0.48), 22, 0.045, 0.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
