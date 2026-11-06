import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vehicle classes that only carry parcels; the ride estimate still returns
/// them ("Messenger Bike" / "Messenger Car"), so the ride page drops them.
const kDeliveryOnlyVehicleClasses = {'messenger', 'motorcycle_delivery'};

/// `vehicle_type_id` → `vehicle_class` from
/// `GET /api/vehicle-types?active_only=true`. Empty when it can't be read
/// (the ride page then falls back to the names). Read once per session and
/// again after a failure.
final rideVehicleClassesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    final res = await ref
        .watch(apiServiceProvider)
        .dio
        .get('/api/vehicle-types', queryParameters: {'active_only': true});
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['items'] ?? data['vehicle_types']) : null);
    if (list is! List) return const {};
    return {
      for (final v in list)
        if (v is Map && v['id'] != null)
          '${v['id']}': '${v['vehicle_class'] ?? ''}'.toLowerCase(),
    };
  } catch (e) {
    debugPrint('Vehicle types: unavailable ($e)');
    // Not cached: the next estimate tries again.
    Future.microtask(ref.invalidateSelf);
    return const {};
  }
});

/// Whether a ride option is a parcel-only type: by its class when the type
/// list has it, otherwise by its name.
bool isDeliveryOnlyVehicle({
  required String vehicleTypeId,
  required String vehicleTypeName,
  required String displayName,
  required Map<String, String> classes,
}) {
  final cls = classes[vehicleTypeId];
  if (cls != null && cls.isNotEmpty) {
    return kDeliveryOnlyVehicleClasses.contains(cls);
  }
  final key = '$vehicleTypeName $displayName'.toLowerCase();
  return key.contains('messenger') || key.contains('ส่งของ');
}
