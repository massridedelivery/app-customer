import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/map_marker_providers.dart';
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';

final decodedPolylineProvider = Provider.autoDispose<List<LatLng>>((ref) {
  final encodedPolyline = ref.watch(
    bookingControllerProvider.select((s) => s.value?.encodedPolyline),
  );
  if (encodedPolyline == null || encodedPolyline.isEmpty) {
    return [];
  }
  final points = PolylineDecoder.decodePolyline(encodedPolyline);
  assert(() {
    debugPrint(
      'BookingMap polyline: encodedLen=${encodedPolyline.length}, '
      'points=${points.length}, '
      'first=${points.isNotEmpty ? points.first : null}, '
      'last=${points.isNotEmpty ? points.last : null}',
    );
    return true;
  }());
  return points;
});

class BookingMapWidget extends ConsumerWidget {
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;

  const BookingMapWidget({
    super.key,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
  });

  void _fitMapToMarkers(
    GoogleMapController controller,
    LatLng pickup,
    LatLng dropoff,
  ) {
    // Calculate bounding box
    double minLat = pickup.latitude < dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    double maxLat = pickup.latitude > dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    double minLng = pickup.longitude < dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    double maxLng = pickup.longitude > dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;

    // Add some padding to bounds calculation
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Padding parameters ensure pins don't get covered by UI elements
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickup = ref.watch(
      homeControllerProvider.select((s) => s.pickupLocation),
    );
    final dropoff = ref.watch(
      homeControllerProvider.select((s) => s.dropoffLocation),
    );

    // Watch the decoded polyline points
    final polylinePoints = ref.watch(decodedPolylineProvider);

    final pickupIconAsync = ref.watch(pickupMarkerProvider);
    final dropoffIconAsync = ref.watch(dropoffMarkerProvider);

    if (pickup == null || dropoff == null) return const SizedBox.shrink();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      // Reserve the top safe area (+ room for the address bubbles) and the
      // bottom sheet space so fit-to-bounds keeps both pins in the visible
      // band and their bubbles never land under the status bar.
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 96,
        bottom: 300,
      ),
      onMapCreated: (controller) {
        _fitMapToMarkers(controller, pickup, dropoff);
        if (onMapCreated != null) {
          onMapCreated!(controller);
        }
      },
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon:
              pickupIconAsync.value ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          icon:
              dropoffIconAsync.value ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints.isNotEmpty
              ? polylinePoints
              : [pickup, dropoff],
          color: AppColors.primary,
          width: 5,
        ),
      },
    );
  }
}
