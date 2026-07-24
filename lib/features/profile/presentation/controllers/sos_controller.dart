import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/data/datasources/sos_remote_data_source.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sos_controller.g.dart';

/// SOS incident history (`GET /api/customer/sos/history`).
@riverpod
Future<List<dynamic>> sosHistory(Ref ref) async {
  return ref.read(sosRemoteDataSourceProvider).getHistory();
}

/// Bangkok fallback used only when no location can be resolved at all.
const _fallbackLat = 13.7563;
const _fallbackLng = 100.5018;

/// Handles triggering an emergency SOS. State is `isTriggering`.
@riverpod
class SosController extends _$SosController {
  @override
  bool build() => false;

  /// Sends an SOS with the user's real location and the active trip id (if any).
  /// Returns true on success.
  Future<bool> triggerSos() async {
    state = true;
    try {
      final (lat, lng) = await _resolveLocation();
      final jobId = ref.read(authControllerProvider).activeJobId;

      // Body shape per POST /api/customer/sos: flat lat/lng (not nested).
      await ref.read(sosRemoteDataSourceProvider).trigger({
        'job_id': ?jobId,
        'lat': lat,
        'lng': lng,
        'reason': 'ผู้ใช้กดปุ่ม SOS ฉุกเฉิน',
      });
      return true;
    } catch (e) {
      debugPrint('Failed to trigger SOS: $e');
      return false;
    } finally {
      state = false;
    }
  }

  /// Best-effort fresh GPS fix, falling back to the last known location and
  /// finally a fixed default so an emergency signal is never dropped.
  Future<(double lat, double lng)> _resolveLocation() async {
    try {
      final location = Location();

      var serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }

      if (serviceEnabled) {
        var permission = await location.hasPermission();
        if (permission == PermissionStatus.denied) {
          permission = await location.requestPermission();
        }
        if (permission == PermissionStatus.granted ||
            permission == PermissionStatus.grantedLimited) {
          final data = await location.getLocation();
          if (data.latitude != null && data.longitude != null) {
            return (data.latitude!, data.longitude!);
          }
        }
      }
    } catch (e) {
      debugPrint('SOS: fresh location failed, using fallback: $e');
    }

    final lastKnown = ref.read(homeControllerProvider).currentLocation;
    if (lastKnown != null) {
      return (lastKnown.latitude, lastKnown.longitude);
    }
    return (_fallbackLat, _fallbackLng);
  }
}
