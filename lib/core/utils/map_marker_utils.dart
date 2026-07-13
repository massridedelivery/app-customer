import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerUtils {
  static Future<BitmapDescriptor> getAssetMarker({
    required String assetPath,
    required Color color,
    double width = 100,
    double height = 100,
  }) async {
    // For flutter_svg 2.x:
    final SvgAssetLoader loader = SvgAssetLoader(assetPath);
    final PictureInfo pictureInfo = await vg.loadPicture(loader, null);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(pictureRecorder);

    final ui.Rect viewport = ui.Rect.fromLTWH(
      0,
      0,
      pictureInfo.size.width,
      pictureInfo.size.height,
    );

    // Scale to fit
    final double scaleX = width / pictureInfo.size.width;
    final double scaleY = height / pictureInfo.size.height;
    canvas.scale(scaleX, scaleY);

    // Use ColorFilter to apply the requested color
    final ui.Paint paint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(color, ui.BlendMode.srcIn);

    canvas.saveLayer(viewport, paint);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    // Cleanup
    pictureInfo.picture.dispose();

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  /// Centralized Pickup Marker (Green pin with white hole)
  static Future<BitmapDescriptor> createPickupMarker() async {
    return _createCompositeMarker(
      backgroundColor: const Color(0xFF24A12F), // Green as per image
      iconColor: Colors.white,
    );
  }

  /// Centralized Dropoff Marker (Red pin with white hole)
  static Future<BitmapDescriptor> createDropoffMarker() async {
    return _createCompositeMarker(
      backgroundColor: const Color(0xFFE11E3F), // Red as per image
      iconColor: Colors.white,
    );
  }

  static Future<BitmapDescriptor> _createCompositeMarker({
    required Color backgroundColor,
    required Color iconColor,
    double size = 120, // Slightly larger for better detail
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(pictureRecorder);

    // 1. Load SVG Pin (icLocationFill is a pin shape with a hole)
    final SvgAssetLoader loader = SvgAssetLoader(
      'assets/images/icons/ic_location_fill.svg',
    );
    final PictureInfo pictureInfo = await vg.loadPicture(loader, null);

    // SVG is 24x24, we scale it to fit our size
    final double scale = size / 24.0;

    canvas.save();
    canvas.scale(scale, scale);

    // 2. Draw Shadow (optional but helps it pop)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1);
    // Draw a small circle as shadow for the pin's tip
    canvas.drawCircle(const Offset(12, 22), 2, shadowPaint);

    // 3. Draw the Pin (Colored)
    // We use a Paint with the background color
    final ui.Paint pinPaint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(backgroundColor, ui.BlendMode.srcIn);

    canvas.saveLayer(ui.Rect.fromLTWH(0, 0, 24, 24), pinPaint);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    // 4. Draw White Circle in the hole
    // The hole in ic_location_fill.svg is centered at (12, 11) with radius ~3
    final Paint holePaint = Paint()..color = iconColor;
    canvas.drawCircle(const Offset(12, 11), 3.5, holePaint);

    canvas.restore();

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    pictureInfo.picture.dispose();

    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
}
