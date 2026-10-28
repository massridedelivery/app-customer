import 'dart:async';

import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/call/data/call_repository.dart';
import 'package:customer_app/features/call/data/call_system_ui.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final voipTokenRegistrarProvider = Provider<VoipTokenRegistrar>((ref) {
  return VoipTokenRegistrar(ref);
});

/// Keeps the backend holding this iPhone's PushKit token, which is what rings
/// it (CallKit) for a driver's call while the app is closed: sent after every
/// login and whenever PushKit hands out a new one, deleted on logout. Separate
/// from the FCM token.
class VoipTokenRegistrar {
  VoipTokenRegistrar(this._ref);

  final Ref _ref;
  bool _started = false;
  String? _registered;

  /// A Xcode (development) build's tokens only work on APNs' sandbox.
  static bool get _sandbox => !kReleaseMode;

  /// This build's bundle id (`com.massdrive.customerApp` or `….develop`).
  static Future<String?> _bundleId() async {
    try {
      return (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {
      return null;
    }
  }

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void start() {
    if (_started || !_supported) return;
    _started = true;
    _ref.listen(authControllerProvider.select((s) => s.isAuthenticated), (
      previous,
      loggedIn,
    ) {
      if (loggedIn && previous != true) unawaited(register());
    });
    _ref.read(callSystemUiProvider).events.listen((e) {
      if (e is SystemVoipTokenChanged) unawaited(register());
    });
    if (_ref.read(authControllerProvider).isAuthenticated) {
      unawaited(register());
    }
  }

  Future<void> register() async {
    if (!_supported || !_ref.read(authControllerProvider).isAuthenticated) {
      return;
    }
    try {
      final token = await _ref.read(callSystemUiProvider).voipToken();
      if (token == null) return;
      await _ref
          .read(callRepositoryProvider)
          .registerVoipToken(
            token,
            sandbox: _sandbox,
            bundleId: await _bundleId(),
          );
      _registered = token;
    } catch (e) {
      debugPrint('Call: VoIP token registration failed (ignored): $e');
    }
  }

  /// Called from logout while the session is still valid.
  Future<void> unregisterOnLogout() async {
    if (!_supported) return;
    try {
      final token =
          _registered ?? await _ref.read(callSystemUiProvider).voipToken();
      if (token == null) return;
      await _ref
          .read(callRepositoryProvider)
          .unregisterVoipToken(
            token,
            sandbox: _sandbox,
            bundleId: await _bundleId(),
          );
      _registered = null;
    } catch (e) {
      debugPrint('Call: VoIP token unregister failed (ignored): $e');
    }
  }
}
