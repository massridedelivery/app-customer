import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The build this app is, read once at startup ([load]) and reused: sent on
/// every API request ([headers]) and to the version check, so the admin's
/// "App iOS 1.0.5+129" and the force-update rules see the same string.
abstract class AppBuild {
  /// `<version>+<build>` from the bundle, e.g. `1.0.5+129`; "" before [load]
  /// (or when the bundle can't be read).
  static String get version => _version;
  static String _version = '';

  /// `ios`, `android` or `web`.
  static String get platform => kIsWeb
      ? 'web'
      : defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = format(info.version, info.buildNumber);
    } catch (e) {
      debugPrint('AppBuild: package info unavailable: $e');
    }
  }

  /// `1.0.5` + `129` → `1.0.5+129`; just the version when there is no build
  /// number. Empty when the result isn't something the backend keeps
  /// (printable ASCII, at most 64 characters).
  @visibleForTesting
  static String format(String version, String buildNumber) {
    final v = version.trim();
    final b = buildNumber.trim();
    final s = b.isEmpty ? v : '$v+$b';
    if (s.length > 64 || !RegExp(r'^[\x21-\x7e]+$').hasMatch(s)) return '';
    return s;
  }

  /// The `X-App-Version` / `X-App-Platform` headers; no version header until
  /// [load] has read one. Never anything about the device or the user.
  static Map<String, String> get headers => {
    if (_version.isNotEmpty) 'X-App-Version': _version,
    'X-App-Platform': platform,
  };

  @visibleForTesting
  static set debugVersion(String v) => _version = v;
}
