import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/polyline_decoder.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';
import 'package:customer_app/features/food_order/presentation/screens/live_food_tracking_screen.dart';

/// Memoized decode of the delivery route — this map rebuilds on every rider
/// location update, so decoding inline in build would redo the whole route
/// each time.
final foodRoutePolylineProvider = Provider.autoDispose<List<LatLng>>((ref) {
  final polyline = ref.watch(
    liveFoodTrackingControllerProvider.select((s) => s.order?.polyline),
  );
  if (polyline == null || polyline.isEmpty) return const [];
  return PolylineDecoder.decodePolyline(polyline);
});

class LiveFoodTrackingMap extends ConsumerStatefulWidget {
  final String orderId;
  final OrderState currentState;
  final BitmapDescriptor? restaurantIcon;
  final BitmapDescriptor? customerIcon;

  const LiveFoodTrackingMap({
    super.key,
    required this.orderId,
    required this.currentState,
    this.restaurantIcon,
    this.customerIcon,
  });

  @override
  ConsumerState<LiveFoodTrackingMap> createState() => _LiveFoodTrackingMapState();
}

class _LiveFoodTrackingMapState extends ConsumerState<LiveFoodTrackingMap> {
  GoogleMapController? _mapController;

  static const LatLng _restaurantPos = LatLng(13.7580, 100.5010);
  static const LatLng _customerPos = LatLng(13.7650, 100.5100);

  void _fitBounds(LatLng restaurant, LatLng customer, LatLng rider) {
    if (_mapController == null) return;

    final points = [restaurant, customer, rider];
    double minLat = points.map((p) => p.latitude).reduce(min);
    double maxLat = points.map((p) => p.latitude).reduce(max);
    double minLng = points.map((p) => p.longitude).reduce(min);
    double maxLng = points.map((p) => p.longitude).reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentState != OrderState.delivery && widget.currentState != OrderState.delivered) {
      return const SizedBox.shrink();
    }

    final restaurantLocation = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.restaurantLocation),
    );
    final order = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.order),
    );
    final driverLocation = ref.watch(
      liveFoodTrackingControllerProvider.select((s) => s.driverLocation),
    );

    final orderRef = order;
    final actualRestaurantPos = restaurantLocation ??
        (orderRef != null && orderRef.restaurantLat != null && orderRef.restaurantLng != null
            ? LatLng(orderRef.restaurantLat!, orderRef.restaurantLng!)
            : _restaurantPos);
    final actualCustomerPos = orderRef != null
        ? LatLng(orderRef.deliveryLat, orderRef.deliveryLng)
        : _customerPos;
    final riderPos = driverLocation ?? actualRestaurantPos;

    final decodedRoute = ref.watch(foodRoutePolylineProvider);
    final polylinePoints = decodedRoute.isNotEmpty
        ? decodedRoute
        : <LatLng>[actualRestaurantPos, riderPos, actualCustomerPos];

    // Listen to driver location updates to animate the map camera
    ref.listen(
      liveFoodTrackingControllerProvider.select((s) => s.driverLocation),
      (previous, next) {
        if (next != null && _mapController != null) {
          _fitBounds(actualRestaurantPos, actualCustomerPos, next);
        }
      },
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: riderPos,
        zoom: 14.5,
      ),
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      padding: const EdgeInsets.only(bottom: 350, top: 40),
      onMapCreated: (controller) {
        _mapController = controller;
        // Fit camera bounds immediately on map load
        _fitBounds(actualRestaurantPos, actualCustomerPos, riderPos);
      },
      markers: {
        Marker(
          markerId: const MarkerId('restaurant'),
          position: actualRestaurantPos,
          icon: widget.restaurantIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
        ),
        Marker(
          markerId: const MarkerId('customer'),
          position: actualCustomerPos,
          icon: widget.customerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
        ),
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: AppColors.foundationGreen500,
          width: 4,
        ),
      },
    );
  }
}
