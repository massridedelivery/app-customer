import 'package:google_maps_flutter/google_maps_flutter.dart';

/// App-wide default map coordinates.
///
/// Centralises the central-Bangkok fallback that was previously duplicated as a
/// magic `LatLng(13.7563, 100.5018)` (and its raw `13.7563` / `100.5018`
/// components) across ~14 files. This is a display / geo-query-bias fallback
/// only — it is never seeded as a bookable pickup (see [HomeController], which
/// keeps the pickup null until a real device location resolves).
class MapDefaults {
  const MapDefaults._();

  /// Central Bangkok latitude, for `location?.latitude ?? …` style fallbacks.
  static const double bangkokLat = 13.7563;

  /// Central Bangkok longitude, for `location?.longitude ?? …` style fallbacks.
  static const double bangkokLng = 100.5018;

  /// Central Bangkok — default map camera target and geo-query bias used when
  /// the device location is unknown.
  static const LatLng bangkokCenter = LatLng(bangkokLat, bangkokLng);
}
