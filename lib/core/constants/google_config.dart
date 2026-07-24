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
  static const String _androidPlacesApiKey =
      'AIzaSyBO2_0D2M89FTl1shkEczC1klunUrOqlFs';
  static const String _iosPlacesApiKey =
      'AIzaSyAlgz6GR3iQ-u0elel8OAnnGow0FlSMe2M';

  /// The Places API key for the current platform. A non-empty per-environment
  /// override from [Env] (env/*.json) takes precedence over the baked-in key.
  static String get placesApiKey {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Env.googlePlacesKeyIOS.isNotEmpty
            ? Env.googlePlacesKeyIOS
            : _iosPlacesApiKey;
      default:
        return Env.googlePlacesKeyAndroid.isNotEmpty
            ? Env.googlePlacesKeyAndroid
            : _androidPlacesApiKey;
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
