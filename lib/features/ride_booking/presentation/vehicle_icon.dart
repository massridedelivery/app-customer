/// The 3D vehicle picture for a vehicle type, by its name.
String vehicleIconFor(String typeName) {
  final n = typeName.toLowerCase();
  if (n.contains('bike') || n.contains('motorcycle')) {
    return 'assets/images/icons/3d/ic_car_scooter.png';
  }
  if (n.contains('luxury')) {
    return 'assets/images/icons/3d/ic_car_luxury.png';
  }
  if (n.contains('premium')) {
    return 'assets/images/icons/3d/ic_car_premium.png';
  }
  if (n.contains('xl') ||
      n.contains('van') ||
      n.contains('suv') ||
      n.contains('6')) {
    return 'assets/images/icons/3d/ic_car_xl.png';
  }
  if (n.contains('comfort')) {
    return 'assets/images/icons/3d/ic_car_comfort.png';
  }
  if (n.contains('tuk')) {
    return 'assets/images/icons/3d/ic_car_tuktuk.png';
  }
  // economy / saver / eco and anything else → the clean sedan.
  return 'assets/images/icons/3d/ic_car_economy.png';
}
