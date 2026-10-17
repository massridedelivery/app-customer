import 'package:customer_app/core/configs/app_env.dart';
import 'package:flutter/foundation.dart';

/// Configuration for direct Google Maps Platform (Places API) calls.
///
/// NOTE: These keys must have the **Places API** enabled. Application
/// restrictions (Android app / iOS app) do NOT apply to web-service HTTP calls
/// — for the Places web service, restrict by API ("Places API") and, if needed,
/// IP/HTTP-referrer, not by app.
///
/// The Maps SDK keys used for rendering the map live natively in
/// `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`
/// and are a different concern from these.
abstract class GoogleConfig {
  /// No Google web-service key ships in the app any more. Place search and
  /// directions go through the BE (`/api/places/*`, `/api/directions`); the
  /// old baked-in keys were dead anyway — Google rejected the Android one as
  /// invalid and the iOS one isn't authorized for Directions. An env/*.json
  /// override still works for local debugging; with none set, Roads and the
  /// direct Places fallback skip their calls.
  static String get placesApiKey {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Env.googlePlacesKeyIOS;
      default:
        return Env.googlePlacesKeyAndroid;
    }
  }

  /// Base URL for the legacy Places web service.
  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  /// Language + region bias for results (Thai / Thailand).
  static const String language = 'th';
  static const String region = 'th';
  static const String components = 'country:th';

  static bool get isConfigured => placesApiKey.isNotEmpty;
}
