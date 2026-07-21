import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A network image that **downsizes its decode** to the display size.
///
/// Plain `Image.network` decodes the full-resolution source into memory even
/// when it's rendered into a small slot, which spikes memory and drops frames
/// while scrolling a list of thumbnails. This widget passes `cacheWidth` (in
/// physical pixels = logical width × devicePixelRatio) so the engine decodes at
/// the size actually shown. It also renders a consistent grey fallback for a
/// null/empty URL or a load error, replacing the boilerplate `errorBuilder`
/// containers that were copy-pasted across the food/restaurant screens.
///
/// Pass a finite [width] for fixed thumbnails; leave it null for a full-bleed
/// image (the decode target then falls back to the screen width).
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image,
    this.fallbackIconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _fallback();

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = width;
    // Decode to the box width when bounded, else the screen width — so a
    // full-bleed hero still downsizes instead of decoding at source resolution.
    final logicalTarget = (w != null && w.isFinite)
        ? w
        : MediaQuery.sizeOf(context).width;

    return Image.network(
      u,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (logicalTarget * dpr).round(),
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.semanticGrayNeutralBgLightgray,
      child: Icon(
        fallbackIcon,
        color: AppColors.semanticGrayNeutralFgLowOnWhite,
        size: fallbackIconSize,
      ),
    );
  }
}
