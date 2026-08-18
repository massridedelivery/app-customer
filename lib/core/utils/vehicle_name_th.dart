/// Thai display names for vehicle types.
///
/// The fare-estimate / vehicle-type APIs return only English labels
/// (`display_name`, e.g. "Comfort Car") with no localized field, so the Thai
/// name has to be produced on the client. This maps the known English set
/// exactly, and falls back to a `contains()` match on the semantic
/// `vehicle_type_name` (mirroring `getVehicleIcon`) so a new/renamed type
/// degrades to a sensible Thai label instead of raw English. If nothing
/// matches, the original English `displayName` is returned unchanged.
String vehicleNameTh(String displayName, {String? vehicleTypeName}) {
  const exact = <String, String>{
    'Comfort Car': 'รถ Comfort',
    'Economy Car': 'รถ Eco car',
    'Messenger Bike': 'มอเตอร์ไซค์ส่งของ',
    'Messenger Car': 'รถส่งของ',
    'Motorcycle (Ride Only)': 'มอเตอร์ไซต์ (ผู้โดยสาร)',
    'Tuk-Tuk': 'ตุ๊กตุ๊ก',
    'Van': 'รถตู้',
  };
  final hit = exact[displayName.trim()];
  if (hit != null) return hit;

  final key = (vehicleTypeName ?? displayName).toLowerCase();
  if (key.contains('messenger') && key.contains('bike')) return 'มอเตอร์ไซค์ส่งของ';
  if (key.contains('messenger')) return 'รถส่งของ';
  if (key.contains('tuk')) return 'ตุ๊กตุ๊ก';
  if (key.contains('van')) return 'รถตู้';
  if (key.contains('luxury')) return 'รถหรู';
  if (key.contains('premium')) return 'รถพรีเมียม';
  if (key.contains('comfort')) return 'รถ Comfort';
  if (key.contains('economy') || key.contains('eco')) return 'รถ Eco car';
  if (key.contains('motorcycle') || key.contains('bike')) {
    return 'มอเตอร์ไซต์ (ผู้โดยสาร)';
  }
  if (key.contains('car')) return 'รถยนต์';
  return displayName;
}
