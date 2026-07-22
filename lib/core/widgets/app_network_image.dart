import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A network image that is **disk-cached and decode-downsized**.
///
/// Backed by [CachedNetworkImage]: the source is cached on disk (so it isn't
/// re-downloaded across scrolls or app restarts) and decoded at the display
/// size — `memCacheWidth`/`maxWidthDiskCache` = logical width × devicePixelRatio
/// — instead of at full resolution, which is what spikes memory and drops
/// frames when scrolling a list of thumbnails. A consistent grey placeholder
/// shows while loading and a grey icon on error or a null/empty URL, replacing
/// the boilerplate `errorBuilder` containers that were copy-pasted across the
/// food/restaurant screens.
///
/// Pass a finite [width] for fixed thumbnails; leave it null for a full-bleed
/// image (the decode/cache target then falls back to the screen width).
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
    // Decode/cache to the box width when bounded, else the screen width — so a
    // full-bleed hero still downsizes instead of at source resolution.
    final logicalTarget = (w != null && w.isFinite)
        ? w
        : MediaQuery.sizeOf(context).width;
    final cachePx = (logicalTarget * dpr).round();

    return CachedNetworkImage(
      imageUrl: u,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cachePx,
      maxWidthDiskCache: cachePx,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _fallback(),
    );
  }

  /// Neutral box shown while the image loads (no icon — distinguishes loading
  /// from the error state).
  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.semanticGrayNeutralBgLightgray,
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
