/// A licence plate with its province: `1กข 1234 กรุงเทพมหานคร`. Thai plates
/// repeat across provinces, so the province is part of telling cars apart.
///
/// The province is left off when empty (most drivers don't have one yet), and
/// a province without a plate gives '' — it means nothing on its own. The
/// plate comes first so an ellipsis cuts the province, never the plate.
String formatPlate(String? plate, String? province) {
  final p = plate?.trim() ?? '';
  if (p.isEmpty) return '';
  final prov = province?.trim() ?? '';
  return prov.isEmpty ? p : '$p $prov';
}
