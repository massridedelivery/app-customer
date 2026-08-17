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

/// A very faint white brand pattern (concentric rings + a soft blob + scattered
/// dots) meant to sit behind the content of a red gradient hero header. Adds a
/// little depth without hurting the readability of white text / the search bar.
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
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Concentric rings tucked into the top-right, partly off-canvas.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.08);
    final ringCenter = Offset(w * 0.88, h * 0.02);
    canvas.drawCircle(ringCenter, 48, ring);
    canvas.drawCircle(ringCenter, 82, ring);
    canvas.drawCircle(ringCenter, 116, ring);

    // A soft filled blob anchored to the bottom-left corner.
    canvas.drawCircle(
      Offset(w * 0.02, h * 0.98),
      82,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // A handful of scattered dots for texture.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.12);
    const spots = [
      Offset(0.16, 0.34),
      Offset(0.30, 0.64),
      Offset(0.52, 0.24),
      Offset(0.68, 0.54),
      Offset(0.44, 0.82),
      Offset(0.60, 0.88),
    ];
    for (final s in spots) {
      canvas.drawCircle(Offset(s.dx * w, s.dy * h), 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
