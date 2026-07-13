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

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  final Location _location = Location();

  /// Live camera center while the user pans — kept out of [HomeState] so
  /// per-frame camera events don't rebuild every watcher.
  LatLng? _liveMapCenter;

  @override
  HomeState build() {
    _initLocation();
    _loadSavedPlaces();
    _loadDefaultPlace();
    _loadRecentPlaces();
    // Start with default BKK coordinates and no loading screen
    return const HomeState(
      isLoading: false,
      currentLocation: LatLng(13.7563, 100.5018),
      mapCenter: LatLng(13.7563, 100.5018),
      pickupLocation: LatLng(13.7563, 100.5018),
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
      );

      // 2. Get Address (Network call, can be slow)
      try {
        List<geocoding.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = '${p.name}, ${p.locality}';
          state = state.copyWith(pickupAddress: address);
        }
      } catch (e) {
        state = state.copyWith(pickupAddress: 'Unknown Address');
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      state = state.copyWith(pickupAddress: 'Failed to locate');
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

    final latLng = _liveMapCenter ?? state.mapCenter;
    if (latLng == null) return;

    // Commit the final center so save-place / selection read the settled value.
    state = state.copyWith(mapCenter: latLng);

    String? address;
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = '${p.name}, ${p.street}, ${p.subLocality}, ${p.locality}';
        // Clean up "Unknown" or empty parts
        address = address
            .replaceAll('Unnamed Road, ', '')
            .replaceAll(', ,', ',');
      }
    } catch (e) {
      address = 'Selected Location';
    }

    state = state.copyWith(tempAddress: address, tempLocation: latLng);
  }

  void startSelection({RideSelectionMode mode = RideSelectionMode.pickup}) {
    state = state.copyWith(
      selectionMode: mode,
      isSearching: true,
    );
  }

  void confirmSelection() {
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
    }
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
        if (state.pickupAddress == null || state.pickupAddress == 'Unknown Address' || state.pickupAddress == 'Failed to locate') {
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
        if (state.pickupAddress == null || state.pickupAddress == 'Unknown Address' || state.pickupAddress == 'Failed to locate') {
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
