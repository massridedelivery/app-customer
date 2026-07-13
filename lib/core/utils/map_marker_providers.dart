import 'package:customer_app/core/utils/map_marker_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// App-wide cached marker bitmaps. Rasterising the SVG pins costs tens of ms;
/// with these providers it happens once per app session instead of once per
/// screen visit (keepAlive by default — non-autoDispose FutureProvider).
final pickupMarkerProvider = FutureProvider<BitmapDescriptor>((ref) async {
  return MapMarkerUtils.createPickupMarker();
});

final dropoffMarkerProvider = FutureProvider<BitmapDescriptor>((ref) async {
  return MapMarkerUtils.createDropoffMarker();
});
