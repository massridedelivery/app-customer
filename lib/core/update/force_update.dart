import 'dart:convert';
import 'dart:io' show Platform;

import 'package:customer_app/core/configs/app_env.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// An update the app asks for: blocking when it comes from [forceUpdateProvider],
/// dismissible when it comes from [suggestUpdateProvider].
class AppUpdate {
  const AppUpdate({
    required this.storeUrl,
    required this.currentVersion,
    this.latestVersion,
    this.message,
    this.messageTh,
    this.playImmediate = false,
  });

  /// App Store / Play Store page for the app.
  final String storeUrl;
  final String currentVersion;

  /// The version to update to, when known (Play doesn't expose it).
  final String? latestVersion;

  /// The admin's note for this update (English / Thai), if any.
  final String? message;
  final String? messageTh;

  /// Play allows its in-app full-screen ("immediate") update flow.
  final bool playImmediate;

  /// The admin's note in [languageCode], falling back to the other language.
  String? note(String languageCode) {
    final text = languageCode == 'th'
        ? (messageTh ?? message)
        : (message ?? messageTh);
    return text != null && text.trim().isNotEmpty ? text.trim() : null;
  }
}

/// True when dotted version [store] is higher than [current]: "1.0.10" beats
/// "1.0.9", "1.1" beats "1.0.9". A build suffix ("+12") is ignored and a
/// non-numeric part counts as 0.
bool isNewerVersion(String store, String current) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('-')
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

enum UpdateStatus { ok, suggest, force }

/// The backend's answer (`GET /api/config/version`) for [appVersion]: the
/// admin's minimum version blocks (force), the recommended one nudges
/// (suggest).
class VersionVerdict {
  const VersionVerdict({
    required this.status,
    required this.appVersion,
    this.latestVersion,
    this.storeUrl,
    this.message,
    this.messageTh,
  });

  factory VersionVerdict.fromJson(
    Map<String, dynamic> json, {
    required String appVersion,
  }) => VersionVerdict(
    status: switch (json['status']) {
      'FORCE_UPDATE' => UpdateStatus.force,
      'SUGGEST_UPDATE' => UpdateStatus.suggest,
      _ => UpdateStatus.ok,
    },
    appVersion: json['app_version'] as String? ?? appVersion,
    latestVersion: json['latest_version'] as String?,
    storeUrl: json['store_url'] as String?,
    message: json['message'] as String?,
    messageTh: json['message_th'] as String?,
  );

  final UpdateStatus status;

  /// The installed version this answer was given for.
  final String appVersion;
  final String? latestVersion;
  final String? storeUrl;
  final String? message;
  final String? messageTh;

  Map<String, dynamic> toJson() => {
    'status': switch (status) {
      UpdateStatus.force => 'FORCE_UPDATE',
      UpdateStatus.suggest => 'SUGGEST_UPDATE',
      UpdateStatus.ok => 'OK',
    },
    'app_version': appVersion,
    'latest_version': latestVersion,
    'store_url': storeUrl,
    'message': message,
    'message_th': messageTh,
  };
}

/// What one check decided: [force] blocks the app, [suggest] offers a
/// dismissible update; at most one is set.
typedef UpdateDecision = ({AppUpdate? force, AppUpdate? suggest});

/// Decides from the backend's answer and the store's.
///
/// Only the backend can block. When it can't be reached ([backendFailed]), a
/// [cached] force for this same version still blocks — the admin's minimum
/// didn't go away because the phone is offline — and anything else lets the
/// app run. A newer store version only ever suggests.
UpdateDecision decideUpdate({
  required String currentVersion,
  VersionVerdict? backend,
  bool backendFailed = false,
  VersionVerdict? cached,
  AppUpdate? store,
  String fallbackStoreUrl = '',
}) {
  final verdict =
      backend ??
      (backendFailed &&
              cached?.status == UpdateStatus.force &&
              cached?.appVersion == currentVersion
          ? cached
          : null);
  AppUpdate fromVerdict(VersionVerdict v) {
    final url = v.storeUrl;
    return AppUpdate(
      storeUrl: url != null && url.isNotEmpty
          ? url
          : (store?.storeUrl ?? fallbackStoreUrl),
      currentVersion: currentVersion,
      latestVersion: v.latestVersion,
      message: v.message,
      messageTh: v.messageTh,
      playImmediate: store?.playImmediate ?? false,
    );
  }

  return switch (verdict?.status) {
    UpdateStatus.force => (force: fromVerdict(verdict!), suggest: null),
    UpdateStatus.suggest => (force: null, suggest: fromVerdict(verdict!)),
    _ => (force: null, suggest: store),
  };
}

/// Whether a suggestion for [latest] may show now, given when one was last
/// shown ([lastShown], stored as `version|epochMs`): once a day per
/// version, and at once for a newer one.
bool shouldShowSuggestion(String? lastShown, String? latest, DateTime now) {
  if (lastShown == null) return true;
  final sep = lastShown.lastIndexOf('|');
  if (sep < 0) return true;
  final version = lastShown.substring(0, sep);
  final at = int.tryParse(lastShown.substring(sep + 1));
  if (at == null || version != (latest ?? '')) return true;
  return now.difference(DateTime.fromMillisecondsSinceEpoch(at)) >=
      const Duration(hours: 24);
}

/// Where the check gets its answers; a provider so tests can swap it.
class UpdateSources {
  const UpdateSources();

  /// Local debug runs aren't store builds; don't block development.
  bool get enabled => !kIsWeb && !kDebugMode;

  String get platform => Platform.isIOS ? 'ios' : 'android';

  Future<String> currentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  Future<String> bundleId() async =>
      (await PackageInfo.fromPlatform()).packageName;

  /// The backend's verdict for [version]; null when it has no rules for this
  /// app (a 4xx — e.g. before the backend ships them). Throws when it can't be
  /// reached (offline, timeout, 5xx).
  Future<VersionVerdict?> backend(String version) async {
    try {
      final res =
          await Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ),
          ).get(
            '/api/config/version',
            queryParameters: {
              'app': 'customer',
              'platform': platform,
              'app_version': version,
            },
          );
      final data = res.data;
      if (data is! Map) return null;
      return VersionVerdict.fromJson(
        Map<String, dynamic>.from(data),
        appVersion: version,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500) return null;
      rethrow;
    }
  }

  /// The store's newer version, or null when the installed one is current or
  /// the store can't tell (offline, not listed, a build Play doesn't own).
  Future<AppUpdate?> store(String version) async {
    try {
      return Platform.isIOS
          ? await _appStore(version)
          : await _playStore(version);
    } catch (e) {
      debugPrint('Store update check skipped: $e');
      return null;
    }
  }

  /// iTunes lookup gives the live App Store version and page for our bundle.
  Future<AppUpdate?> _appStore(String version) async {
    final res =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ),
        ).get(
          'https://itunes.apple.com/lookup',
          queryParameters: {'bundleId': await bundleId(), 'country': 'th'},
        );
    final raw = res.data;
    final data = raw is String ? jsonDecode(raw) : raw;
    final results = data is Map ? data['results'] : null;
    if (results is! List || results.isEmpty) return null; // not on the store
    final app = results.first as Map;
    final storeVersion = app['version']?.toString();
    final url = app['trackViewUrl']?.toString();
    if (storeVersion == null || url == null) return null;
    if (!isNewerVersion(storeVersion, version)) return null;
    return AppUpdate(
      storeUrl: url,
      currentVersion: version,
      latestVersion: storeVersion,
    );
  }

  /// Play Core reports whether Play has a newer build for this install.
  Future<AppUpdate?> _playStore(String version) async {
    final update = await InAppUpdate.checkForUpdate();
    if (update.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return AppUpdate(
      storeUrl: playStoreUrl(await bundleId()),
      currentVersion: version,
      playImmediate: update.immediateUpdateAllowed,
    );
  }
}

/// The customer app's App Store page, for when the backend gives no URL.
const appStoreUrl = 'https://apps.apple.com/th/app/id6790326601';

String playStoreUrl(String packageName) =>
    'https://play.google.com/store/apps/details?id=$packageName';

final updateSourcesProvider = Provider<UpdateSources>(
  (ref) => const UpdateSources(),
);

/// SharedPreferences keys: the last backend verdict (for offline launches) and
/// when a suggestion last showed.
const _verdictKey = 'update_verdict';
const _suggestShownKey = 'update_suggest_shown';

/// Checks for updates on launch (from the splash) and again on resume once
/// the last check is [staleAfter] old. Holds the blocking [AppUpdate] when the
/// admin's minimum version is above the installed one, else null; a softer
/// update goes to [suggestUpdateProvider]. Any failure leaves the app usable:
/// the check must never lock people out by mistake.
class ForceUpdateNotifier extends Notifier<AppUpdate?> {
  static const staleAfter = Duration(hours: 6);

  DateTime? _checkedAt;

  @override
  AppUpdate? build() => null;

  /// Runs [check] unless one ran within [staleAfter].
  Future<void> checkIfStale() async {
    final at = _checkedAt;
    if (at != null && DateTime.now().difference(at) < staleAfter) return;
    await check();
  }

  Future<void> check() async {
    final sources = ref.read(updateSourcesProvider);
    if (!sources.enabled) return;
    _checkedAt = DateTime.now();
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final version = await sources.currentVersion();

      VersionVerdict? backend;
      var backendFailed = false;
      try {
        backend = await sources.backend(version);
        if (backend == null) {
          await prefs.remove(_verdictKey);
        } else {
          await prefs.setString(_verdictKey, jsonEncode(backend.toJson()));
        }
      } catch (e) {
        debugPrint('Version check unreachable: $e');
        backendFailed = true;
      }

      // Blocked already: no need to ask the store.
      final AppUpdate? store = backend?.status == UpdateStatus.force
          ? null
          : await sources.store(version);

      final decision = decideUpdate(
        currentVersion: version,
        backend: backend,
        backendFailed: backendFailed,
        cached: backendFailed ? _cached(prefs.getString(_verdictKey)) : null,
        store: store,
        fallbackStoreUrl: sources.platform == 'ios'
            ? appStoreUrl
            : playStoreUrl(await sources.bundleId()),
      );
      if (!ref.mounted) return;
      state = decision.force;
      if (decision.suggest != null) {
        ref.read(suggestUpdateProvider.notifier).offer(decision.suggest!);
      }
    } catch (e) {
      debugPrint('Update check skipped: $e');
    }
  }

  VersionVerdict? _cached(String? raw) {
    if (raw == null) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return VersionVerdict.fromJson(
        json,
        appVersion: json['app_version'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

final forceUpdateProvider = NotifierProvider<ForceUpdateNotifier, AppUpdate?>(
  ForceUpdateNotifier.new,
);

/// A dismissible update waiting to be offered (the main screen shows it), at
/// most once a day per version.
class SuggestUpdateNotifier extends Notifier<AppUpdate?> {
  @override
  AppUpdate? build() => null;

  void offer(AppUpdate update) {
    final last = ref
        .read(sharedPreferencesProvider)
        .getString(_suggestShownKey);
    if (shouldShowSuggestion(last, update.latestVersion, DateTime.now())) {
      state = update;
    }
  }

  /// The dialog is on screen: don't offer this version again for a day.
  Future<void> shown() async {
    final update = state;
    state = null;
    if (update == null) return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _suggestShownKey,
          '${update.latestVersion ?? ''}|${DateTime.now().millisecondsSinceEpoch}',
        );
  }
}

final suggestUpdateProvider =
    NotifierProvider<SuggestUpdateNotifier, AppUpdate?>(
      SuggestUpdateNotifier.new,
    );
