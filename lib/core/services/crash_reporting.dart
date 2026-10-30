import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:customer_app/core/configs/app_env.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Crash and error reports to Firebase Crashlytics: native crashes on iOS and
/// Android plus every uncaught Flutter/Dart error, so a broken screen shows up
/// in the console instead of in a customer's complaint.
///
/// Off in debug builds. A report carries the flavor, the app version/build and
/// a SHA-256 of the customer id — never a name or phone number (PDPA).
class CrashReporting {
  CrashReporting._();

  static bool _started = false;

  /// Call once, right after Firebase is up. Never throws.
  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      if (kDebugMode) return;

      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      final info = await PackageInfo.fromPlatform();
      await crashlytics.setCustomKey('flavor', Env.flavor.name);
      await crashlytics.setCustomKey('app_version', info.version);
      await crashlytics.setCustomKey('app_build', info.buildNumber);

      // A build made with --dart-define=CRASHLYTICS_TEST=true sends one
      // non-fatal report at launch, to check the console end to end.
      if (const bool.fromEnvironment('CRASHLYTICS_TEST')) {
        await crashlytics.recordError(
          StateError('Crashlytics test report'),
          StackTrace.current,
          reason: 'CRASHLYTICS_TEST build',
        );
      }
    } catch (e) {
      debugPrint('CrashReporting: start failed: $e');
    }
  }

  /// Ties reports to the signed-in customer (hashed) and drops that on logout.
  static void followUser(ProviderContainer container) {
    if (kDebugMode) return;
    void sync(bool signedIn) {
      final token = signedIn
          ? container.read(tokenStorageProvider).getAccessToken()
          : null;
      final id = token == null ? null : userIdFromJwt(token);
      FirebaseCrashlytics.instance
          .setUserIdentifier(id == null ? '' : hashUserId(id))
          .catchError((Object e) => debugPrint('CrashReporting: $e'));
    }

    container.listen<bool>(
      authControllerProvider.select((s) => s.isAuthenticated),
      (_, signedIn) => sync(signedIn),
      fireImmediately: true,
    );
  }
}

/// The `user_id` claim of a JWT, or null.
@visibleForTesting
String? userIdFromJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    final id = claims is Map ? claims['user_id']?.toString() : null;
    return id == null || id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}

/// What Crashlytics sees instead of the customer id.
String hashUserId(String id) => sha256.convert(utf8.encode(id)).toString();
