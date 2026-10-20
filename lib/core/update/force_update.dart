import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The store has a newer build than the one installed, so the app holds on the
/// update screen until the user updates (see `/force-update` in the router).
class StoreUpdate {
  const StoreUpdate({
    required this.storeUrl,
    required this.currentVersion,
    this.storeVersion,
    this.playImmediate = false,
  });

  /// App Store / Play Store page for the app.
  final String storeUrl;
  final String currentVersion;

  /// The store's version; null on Android, where Play doesn't expose it.
  final String? storeVersion;

  /// Play allows its in-app full-screen ("immediate") update flow.
  final bool playImmediate;
}

/// True when dotted version [store] is higher than [current]: "1.0.10" beats
/// "1.0.9", "1.1" beats "1.0.9". A build suffix ("+12") is ignored and a
/// non-numeric part counts as 0.
bool isNewerVersion(String store, String current) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .trim()
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final a = parts(store);
  final b = parts(current);
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Checks the store once per launch (started from the splash). Holds the
/// [StoreUpdate] when the installed version is behind, else null. Any failure
/// — offline, not on the store yet, a sideloaded build Play doesn't own —
/// leaves it null: the check must never lock people out by mistake.
class ForceUpdateNotifier extends Notifier<StoreUpdate?> {
  @override
  StoreUpdate? build() => null;

  Future<void> check() async {
    // Local debug runs aren't store builds; don't block development.
    if (kIsWeb || kDebugMode) return;
    try {
      final info = await PackageInfo.fromPlatform();
      final update = Platform.isIOS
          ? await _appStore(info)
          : Platform.isAndroid
          ? await _playStore(info)
          : null;
      if (update != null) state = update;
    } catch (e) {
      debugPrint('Force-update check skipped: $e');
    }
  }

  /// iTunes lookup gives the live App Store version and page for our bundle.
  Future<StoreUpdate?> _appStore(PackageInfo info) async {
    final res = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ),
    ).get(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': info.packageName, 'country': 'th'},
    );
    final raw = res.data;
    final data = raw is String ? jsonDecode(raw) : raw;
    final results = data is Map ? data['results'] : null;
    if (results is! List || results.isEmpty) return null; // not on the store
    final app = results.first as Map;
    final storeVersion = app['version']?.toString();
    final url = app['trackViewUrl']?.toString();
    if (storeVersion == null || url == null) return null;
    if (!isNewerVersion(storeVersion, info.version)) return null;
    return StoreUpdate(
      storeUrl: url,
      currentVersion: info.version,
      storeVersion: storeVersion,
    );
  }

  /// Play Core reports whether Play has a newer build for this install.
  Future<StoreUpdate?> _playStore(PackageInfo info) async {
    final update = await InAppUpdate.checkForUpdate();
    if (update.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return StoreUpdate(
      storeUrl:
          'https://play.google.com/store/apps/details?id=${info.packageName}',
      currentVersion: info.version,
      playImmediate: update.immediateUpdateAllowed,
    );
  }
}

final forceUpdateProvider = NotifierProvider<ForceUpdateNotifier, StoreUpdate?>(
  ForceUpdateNotifier.new,
);
