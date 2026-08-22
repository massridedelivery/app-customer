import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// Pickup → dropoff route stops shown as a vertical timeline: the standard
/// map-pin icon (`icLocationFill`) in green/red with a **continuous** dashed
/// connector that runs from the green pin all the way down to the red pin (no
/// gap). Use this everywhere a จุดรับ/จุดส่ง pair is displayed so pins and the
/// connector stay identical across the app.
class RouteStops extends StatelessWidget {
  const RouteStops({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLabel = 'จุดรับ',
    this.dropoffLabel = 'จุดส่ง',
    this.pinSize = 20,
    this.labelStyle,
    this.addressStyle,
    this.showLabels = true,
  });

  final String? pickupAddress;
  final String? dropoffAddress;
  final String pickupLabel;
  final String dropoffLabel;
  final double pinSize;
  final TextStyle? labelStyle;
  final TextStyle? addressStyle;

  /// When false, only the address line is shown (no 'จุดรับ'/'จุดส่ง' heading) —
  /// for compact places that just list the two addresses.
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup row is intrinsic-height so the dashed line (Expanded) fills
        // from just under the green pin to the bottom of the row — which is
        // exactly where the red pin begins, making the connector continuous.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: pinSize,
                child: Column(
                  children: [
                    _pin(AppColors.foundationGreen500),
                    const SizedBox(height: 2),
                    Expanded(
                      child: SizedBox(
                        width: 2,
                        child: CustomPaint(
                          painter: _DashedLinePainter(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _stop(pickupLabel, pickupAddress),
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pin(AppColors.foundationRed700),
            const SizedBox(width: 12),
            Expanded(child: _stop(dropoffLabel, dropoffAddress)),
          ],
        ),
      ],
    );
  }

  Widget _pin(Color color) => AppIcons.asset(
        AppAssets.icLocationFill,
        color: color,
        width: pinSize,
        height: pinSize,
      );

  Widget _stop(String label, String? address) {
    final hasAddress = address != null && address.isNotEmpty;
    final textStyle = addressStyle ??
        AppTypography.caption4.copyWith(
          color: AppColors.semanticGrayNeutralFgLowOnWhite,
        );
    if (!showLabels) {
      // Single-line compact: just the address (fall back to the label).
      return Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Text(hasAddress ? address : label, style: textStyle),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle ?? AppTypography.label2),
        const SizedBox(height: 4),
        Text(hasAddress ? address : label, style: textStyle),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  static const double _dashHeight = 3;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + _dashHeight).clamp(0, size.height)),
        paint,
      );
      y += _dashHeight + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
