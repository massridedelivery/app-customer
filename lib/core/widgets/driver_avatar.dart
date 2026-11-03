import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// The assigned driver's profile photo (`driver_info.avatar_url`), round.
///
/// The backend sends a full URL, or no field / null when the driver has no
/// photo. Anything else (a bare media key such as `avatar/<id>/x.jpg`, which
/// older builds sent after a status change) is never joined to a host here: it
/// shows the placeholder, as do a missing value and a failed download. The
/// image is cached by URL, so a refresh with the same URL doesn't flicker, and
/// a new URL (the driver changed photo) replaces the old image once loaded.
class DriverAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final Color backgroundColor;
  final IconData placeholderIcon;
  final Color placeholderColor;

  const DriverAvatar({
    super.key,
    required this.url,
    this.size = 56,
    this.backgroundColor = const Color(0xFFF1F2F5),
    this.placeholderIcon = Icons.person,
    this.placeholderColor = AppColors.semanticGrayNeutralFgLowOnWhite,
  });

  /// [url] when it can be loaded as is, else null.
  static String? usableUrl(String? url) {
    final u = url?.trim() ?? '';
    return u.startsWith('https://') || u.startsWith('http://') ? u : null;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      key: const Key('driverAvatarPlaceholder'),
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(placeholderIcon, color: placeholderColor, size: size * 0.54),
    );
    final u = usableUrl(url);
    if (u == null) return placeholder;
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: cachePx,
        maxWidthDiskCache: cachePx,
        useOldImageOnUrlChange: true,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
