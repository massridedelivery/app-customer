import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app version read from the bundle, e.g. "1.0.3" (no build number).
/// Shown on the profile screen; kept in core so any screen can read it.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
