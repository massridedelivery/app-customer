/// Thai phone input → E.164 (`+66…`), which every `/auth/*` phone endpoint
/// requires: `0812345678` / `812345678` / `+66812345678` → `+66812345678`.
String toE164Thai(String input) {
  var p = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (p.startsWith('+')) return p;
  if (p.startsWith('66') && p.length >= 11) return '+$p';
  if (p.startsWith('0')) p = p.substring(1);
  return '+66$p';
}

/// A Thai number as E.164: +66 then 8–9 digits.
bool isThaiE164(String phone) => RegExp(r'^\+66\d{8,9}$').hasMatch(phone);

/// `+66812345678` → `081 234 5678` for display; other formats pass through.
String displayThaiPhone(String e164) {
  if (!e164.startsWith('+66')) return e164;
  final local = '0${e164.substring(3)}';
  if (local.length != 10) return local;
  return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
}
