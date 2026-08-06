/// Joins the parts of a reverse-geocoded place into one readable line.
///
/// The platform geocoder repeats itself constantly: `name` is usually the house
/// number that `street` already opens with — "229/1" + "229/1 Soi Chaeng
/// Watthana 10" used to render as `229/1, 229/1 Soi Chaeng Watthana 10` — and
/// any field can come back null, blank, or the placeholder "Unnamed Road".
///
/// Parts are kept in the order given, minus the blanks and minus any part that
/// another part already opens with (the longer one wins, so the house number
/// survives inside the street). Redundancy is judged by prefix rather than
/// "contains" on purpose: `14` is a prefix of `14 Soi Ari` and should collapse,
/// but merely appears inside `Soi 140`, where both parts carry meaning.
///
/// Returns an empty string when nothing usable is left — callers decide what to
/// show in that case.
String formatAddressParts(List<String?> parts) {
  const placeholders = {'unnamed road', 'unnamed'};
  final kept = <String>[];

  for (final raw in parts) {
    final part = raw?.trim() ?? '';
    if (part.isEmpty || placeholders.contains(part.toLowerCase())) continue;
    if (kept.any((existing) => _opensWith(existing, part))) continue;
    kept.removeWhere((existing) => _opensWith(part, existing));
    kept.add(part);
  }

  return kept.join(', ');
}

bool _opensWith(String longer, String shorter) =>
    longer.toLowerCase().startsWith(shorter.toLowerCase());
