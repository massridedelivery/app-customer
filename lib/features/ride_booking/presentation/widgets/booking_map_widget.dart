import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/services/google_directions_service.dart';
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

final _directionsServiceProvider = Provider(
  (ref) => GoogleDirectionsService(),
);

/// Route points for the booking map. Prefers the backend polyline; when it's
/// missing, fetches a real road-following route from Google Directions. Returns
/// an empty list until/unless a route resolves, so the map keeps its straight
/// pickup→dropoff fallback in the meantime.
final routePointsProvider = FutureProvider.autoDispose<List<LatLng>>((
  ref,
) async {
  final backendRoute = ref.watch(decodedPolylineProvider);
  if (backendRoute.isNotEmpty) return backendRoute;

  final pickup = ref.watch(
    homeControllerProvider.select((s) => s.pickupLocation),
  );
  final dropoff = ref.watch(
    homeControllerProvider.select((s) => s.dropoffLocation),
  );
  if (pickup == null || dropoff == null) return const <LatLng>[];

  return ref.read(_directionsServiceProvider).route(pickup, dropoff);
});

class BookingMapWidget extends ConsumerStatefulWidget {
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;

  const BookingMapWidget({
    super.key,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  ConsumerState<BookingMapWidget> createState() => _BookingMapWidgetState();
}

class _BookingMapWidgetState extends ConsumerState<BookingMapWidget> {
  GoogleMapController? _controller;

  Future<void> _fitMapToMarkers(
    GoogleMapController controller,
    LatLng pickup,
    LatLng dropoff,
  ) async {
    // Calculate bounding box
    final double minLat = pickup.latitude < dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final double maxLat = pickup.latitude > dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final double minLng = pickup.longitude < dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    final double maxLng = pickup.longitude > dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // onMapCreated can fire before the map's GL surface has a size. Fitting
    // bounds then silently falls back to the min (whole-world) zoom — the map
    // "sometimes doesn't zoom" bug. Fit once soon, then again once it's laid
    // out, so the second pass always lands on the route. 100px keeps the pins
    // clear of the address bubbles / bottom sheet.
    Future<void> fit() async {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } catch (_) {
        // Map not ready yet — the later retry below will take.
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    await fit();
    await Future.delayed(const Duration(milliseconds: 450));
    await fit();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ref.watch(
      homeControllerProvider.select((s) => s.pickupLocation),
    );
    final dropoff = ref.watch(
      homeControllerProvider.select((s) => s.dropoffLocation),
    );

    // Re-fit whenever the pickup or dropoff changes (e.g. the user picks a new
    // destination) so both pins stay in view instead of the map staying on the
    // old route. Fires only on change; the initial fit runs in onMapCreated.
    ref.listen(
      homeControllerProvider.select(
        (s) => (s.pickupLocation, s.dropoffLocation),
      ),
      (prev, next) {
        final (p, d) = next;
        final controller = _controller;
        if (p != null && d != null && controller != null) {
          _fitMapToMarkers(controller, p, d);
        }
      },
    );

    // Backend polyline when present, otherwise the Google Directions route.
    // Empty until it resolves → the Polyline below keeps the straight-line
    // fallback in the meantime.
    final polylinePoints =
        ref.watch(routePointsProvider).asData?.value ?? const <LatLng>[];

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
        _controller = controller;
        _fitMapToMarkers(controller, pickup, dropoff);
        widget.onMapCreated?.call(controller);
      },
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
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
