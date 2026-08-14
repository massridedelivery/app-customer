import 'dart:math' as math;

import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/core/services/google_roads_service.dart';
import 'package:customer_app/core/utils/address_formatter.dart';
import 'package:customer_app/features/home/domain/usecases/add_saved_place_usecase_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_default_place_usecase_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_recent_places_usecase_impl.dart';
import 'package:customer_app/features/home/domain/usecases/get_saved_places_usecase_impl.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

/// Camera-only fallback (central Bangkok), used purely as the initial map
/// centre until the device location resolves. It is deliberately NOT seeded
/// into [HomeState.pickupLocation]/[HomeState.currentLocation]: doing so let a
/// ride be booked from the city centre when GPS was slow or denied.
const LatLng _kMapCameraFallback = MapDefaults.bangkokCenter;

/// Stands in for the address when reverse geocoding returns nothing or fails.
/// Never null: a null [HomeState.tempAddress] means "still resolving", and
/// [HomeController.confirmSelection] blocks on it.
const String _kFallbackPlaceName = 'Selected Location';

/// Snap-to-road tuning (metres). Under [_kSnapMinMeters] the pin is already on a
/// road — leave it. Over [_kSnapMaxMeters] the nearest road is too far (e.g. the
/// middle of a park) — keep the user's point rather than yanking it across the
/// map. Within [_kSnapSkipMeters] of the last snapped point we treat the pin as
/// already snapped and skip another Roads API call.
const double _kSnapMinMeters = 8;
const double _kSnapMaxMeters = 120;
const double _kSnapSkipMeters = 12;

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  final Location _location = Location();

  /// Live camera center while the user pans — kept out of [HomeState] so
  /// per-frame camera events don't rebuild every watcher.
  LatLng? _liveMapCenter;

  /// Sequence number of the newest reverse-geocode lookup, so a slow response
  /// for an abandoned map position can't overwrite a newer one.
  int _geocodeLookup = 0;

  /// The last road point we snapped to. When the camera settles again within
  /// [_kSnapSkipMeters] of it — e.g. right after we animated there — we skip
  /// re-calling the Roads API and re-animating.
  LatLng? _lastSnapResult;

  @override
  HomeState build() {
    _initLocation();
    _loadSavedPlaces();
    _loadDefaultPlace();
    _loadRecentPlaces();
    // Only seed the map camera. currentLocation and pickupLocation stay null
    // until a real source resolves them (GPS in _initLocation, the user's
    // default saved place, or a manual pick) — so a null pickup means
    // "not resolved yet" and callers can gate booking on it instead of
    // silently using the Bangkok fallback.
    return const HomeState(
      isLoading: false,
      mapCenter: _kMapCameraFallback,
    );
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          state = state.copyWith(pickupAddress: 'Location disabled');
          return;
        }
      }

      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          state = state.copyWith(pickupAddress: 'Permission denied');
          return;
        }
      }

      // 1. Get Coordinates (Fastest)
      final locationData = await _location.getLocation();
      final latLng = LatLng(locationData.latitude!, locationData.longitude!);

      // Update position immediately so marker appears
      state = state.copyWith(
        currentLocation: latLng,
        mapCenter: latLng,
        pickupLocation: latLng,
        // No recent/default food location yet → default the food delivery point
        // to the current location so the home shows a real place instead of the
        // "โปรดเลือกสถานที่" prompt. A saved default place still wins if it
        // resolves first (the guard below only fills a still-empty value).
        foodLocation: state.foodLocation ?? latLng,
      );

      // 2. Get Address (Network call, can be slow)
      try {
        List<geocoding.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = '${p.name}, ${p.locality}';
          state = state.copyWith(
            pickupAddress: address,
            // Fill the food address from current location only if nothing (a
            // recent/default place) has claimed it yet.
            foodAddress: state.foodAddress ?? address,
          );
        }
      } catch (e) {
        state = state.copyWith(pickupAddress: 'Unknown Address');
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      state = state.copyWith(pickupAddress: 'Failed to locate');
    }
  }

  /// Fired once when the user starts moving the map. Clear the resolved address
  /// so the pin no longer matches a stale spot — this flips `tempAddress` to
  /// null, which the selection view reads as "resolving" and greys out the
  /// confirm button until [onCameraIdle] geocodes the new centre.
  void onCameraMoveStarted() {
    if (state.selectionMode == RideSelectionMode.none) return;
    if (state.tempAddress != null) {
      state = state.copyWith(tempAddress: null);
    }
  }

  void onCameraMove(CameraPosition position) {
    // Do NOT write state here: this fires every frame while panning (~60/s)
    // and a HomeState mutation rebuilds every watcher — including the map
    // screens themselves. Track the live center privately and commit it once
    // per gesture in [onCameraIdle].
    _liveMapCenter = position.target;
  }

  Future<void> onCameraIdle() async {
    if (state.selectionMode == RideSelectionMode.none) return;

    final raw = _liveMapCenter ?? state.mapCenter;
    if (raw == null) return;

    // Snap the pin onto the nearest drivable road so a point dropped inside a
    // building/soi is reachable by the driver. Best-effort: on failure (incl.
    // the Roads API being disabled on the iOS key) we keep the raw point. Skip
    // when we're already sitting on a freshly snapped point, so animating there
    // doesn't trigger a redundant Roads call / second animation.
    LatLng target = raw;
    bool movedBySnap = false;
    final alreadySnapped =
        _lastSnapResult != null &&
        _metersBetween(raw, _lastSnapResult!) < _kSnapSkipMeters;
    if (FeatureFlags.snapPickupDropoffToRoad && !alreadySnapped) {
      final snapped = await ref
          .read(googleRoadsServiceProvider)
          .nearestRoad(raw);
      if (snapped != null) {
        final distance = _metersBetween(snapped, raw);
        if (distance >= _kSnapMinMeters && distance <= _kSnapMaxMeters) {
          target = snapped;
          movedBySnap = true;
        }
        _lastSnapResult = target;
      }
    }

    // Publish the coordinate BEFORE the reverse geocode below. That lookup is a
    // network call and used to be the only thing that set tempLocation, so
    // confirming while it was in flight committed a null location over a
    // perfectly good pickup/dropoff. Clearing tempAddress marks the pair as
    // "resolving" — [confirmSelection] refuses until the address lands. Bumping
    // mapSnapNonce tells the selection screen to animate the camera onto the
    // snapped road point.
    final int lookup = ++_geocodeLookup;
    state = state.copyWith(
      mapCenter: target,
      tempLocation: target,
      tempAddress: null,
      mapSnapNonce: movedBySnap ? state.mapSnapNonce + 1 : state.mapSnapNonce,
    );

    String address;
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(target.latitude, target.longitude);
      if (placemarks.isEmpty) {
        address = _kFallbackPlaceName;
      } else {
        final p = placemarks.first;
        final formatted = formatAddressParts([
          p.name,
          p.street,
          p.subLocality,
          p.locality,
        ]);
        address = formatted.isEmpty ? _kFallbackPlaceName : formatted;
      }
    } catch (e) {
      address = _kFallbackPlaceName;
    }

    // The user panned again while this lookup was out — a newer one owns the
    // state now, and this stale address must not overwrite it.
    if (lookup != _geocodeLookup) return;

    state = state.copyWith(tempAddress: address);
  }

  /// Approximate great-circle distance in metres (equirectangular projection —
  /// accurate enough at the tens-of-metres scale we snap over).
  static double _metersBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371000;
    const double degToRad = math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * degToRad;
    final double dLng = (b.longitude - a.longitude) * degToRad;
    final double meanLat = ((a.latitude + b.latitude) / 2) * degToRad;
    final double x = dLng * math.cos(meanLat);
    return earthRadius * math.sqrt(dLat * dLat + x * x);
  }

  void startSelection({RideSelectionMode mode = RideSelectionMode.pickup}) {
    state = state.copyWith(
      selectionMode: mode,
      isSearching: true,
    );
  }

  /// Commits the map's current centre as the pickup/dropoff/… for the active
  /// [HomeState.selectionMode]. Returns false — writing nothing — when the
  /// selection hasn't settled yet, i.e. the camera has not come to rest or the
  /// reverse geocode is still out. Callers must not navigate on false: the
  /// previous, valid location is still in place and the user has to wait a beat.
  bool confirmSelection() {
    if (state.tempLocation == null || state.tempAddress == null) return false;

    if (state.selectionMode == RideSelectionMode.pickup) {
      state = state.copyWith(
        pickupAddress: state.tempAddress,
        pickupLocation: state.tempLocation,
        selectionMode: RideSelectionMode.none,
        isSearching: false,
        tempAddress: null,
        tempLocation: null,
      );
    } else if (state.selectionMode == RideSelectionMode.dropoff) {
      state = state.copyWith(
        dropoffAddress: state.tempAddress,
        dropoffLocation: state.tempLocation,
        selectionMode: RideSelectionMode.none,
        isSearching: false,
        tempAddress: null,
        tempLocation: null,
      );
    } else if (state.selectionMode == RideSelectionMode.food) {
      state = state.copyWith(
        foodAddress: state.tempAddress,
        foodLocation: state.tempLocation,
        selectionMode: RideSelectionMode.none,
        isSearching: false,
        tempAddress: null,
        tempLocation: null,
      );
    } else if (state.selectionMode == RideSelectionMode.messengerDropoff) {
      // Messenger reuses the ride dropoff slot; RideSelectionView pops back
      // to the messenger booking screen instead of pushing /booking.
      state = state.copyWith(
        dropoffAddress: state.tempAddress,
        dropoffLocation: state.tempLocation,
        selectionMode: RideSelectionMode.none,
        isSearching: false,
        tempAddress: null,
        tempLocation: null,
      );
    } else {
      // none / savePlace — nothing to commit (save-place goes through
      // [savePlace] with the map centre instead).
      return false;
    }
    return true;
  }

  void cancelSelection() {
    state = state.copyWith(
      selectionMode: RideSelectionMode.none,
      isSearching: false,
      tempAddress: null,
      tempLocation: null,
    );
  }

  void setDropoffLocation(LatLng location, String address) {
    state = state.copyWith(dropoffLocation: location, dropoffAddress: address);
  }

  void setPickupLocation(LatLng location, String address) {
    state = state.copyWith(pickupLocation: location, pickupAddress: address);
  }

  void setFoodLocation(LatLng location, String address) {
    state = state.copyWith(foodLocation: location, foodAddress: address);
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await ref.read(getSavedPlacesUseCaseProvider).call();
      state = state.copyWith(savedPlaces: places);
      try {
        final defaultPlace = places.firstWhere((p) => p.isDefault == true);
        if (state.foodAddress == null) {
          state = state.copyWith(
            foodAddress: defaultPlace.address ?? defaultPlace.name,
            foodLocation: LatLng(defaultPlace.lat, defaultPlace.lng),
          );
        }
        // Fall back to the default saved place whenever GPS hasn't produced a
        // real pickup yet — covers permission-denied/location-disabled/failed
        // and the still-pending case. A non-null pickupLocation means GPS (or a
        // manual pick) already won, so we don't clobber it.
        if (state.pickupLocation == null) {
          state = state.copyWith(
            pickupAddress: defaultPlace.address ?? defaultPlace.name,
            pickupLocation: LatLng(defaultPlace.lat, defaultPlace.lng),
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to load saved places: $e');
    }
  }

  Future<void> _loadDefaultPlace() async {
    try {
      final place = await ref.read(getDefaultPlaceUseCaseProvider).call();
      if (place != null) {
        if (state.foodAddress == null) {
          state = state.copyWith(
            foodAddress: place.address ?? place.name,
            foodLocation: LatLng(place.lat, place.lng),
          );
        }
        // Fall back to the default saved place whenever GPS hasn't produced a
        // real pickup yet — covers permission-denied/location-disabled/failed
        // and the still-pending case. A non-null pickupLocation means GPS (or a
        // manual pick) already won, so we don't clobber it.
        if (state.pickupLocation == null) {
          state = state.copyWith(
            pickupAddress: place.address ?? place.name,
            pickupLocation: LatLng(place.lat, place.lng),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load default place: $e');
    }
  }

  Future<void> _loadRecentPlaces() async {
    try {
      final places = await ref.read(getRecentPlacesUseCaseProvider).call();
      state = state.copyWith(recentPlaces: places);
    } catch (e) {
      debugPrint('Failed to load recent places: $e');
    }
  }

  Future<void> refreshSavedPlaces() async {
    await _loadSavedPlaces();
    await _loadDefaultPlace();
    await _loadRecentPlaces();
  }

  Future<void> savePlace(String name, double lat, double lng) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(addSavedPlaceUseCaseProvider)
          .call(name: name, lat: lat, lng: lng);
      await _loadSavedPlaces();
    } catch (e) {
      debugPrint('Failed to save place: $e');
    }
    state = state.copyWith(isLoading: false);
  }
}
