import 'dart:math';

/// The HTTP header the backend reads to dedupe money-path create calls
/// (SCRUM-50). Retrying a create with the same key returns the ORIGINAL
/// resource instead of a duplicate booking/dispatch/charge.
const String kIdempotencyHeader = 'Idempotency-Key';

/// Generates a random RFC-4122 v4 UUID for use as an [kIdempotencyHeader]
/// value. Mint one when the user taps book / send / order and reuse the same
/// value across every retry of that tap; mint a new one only for a genuinely
/// new action.
String generateIdempotencyKey() {
  final random = Random.secure();
  const hexDigits = '0123456789abcdef';
  final chars = List<int>.generate(36, (index) {
    if (index == 8 || index == 13 || index == 18 || index == 23) {
      return 0x2d; // '-'
    }
    if (index == 14) return 0x34; // version 4
    if (index == 19) {
      // variant 10xx → one of 8, 9, a, b
      return hexDigits.codeUnitAt(8 + random.nextInt(4));
    }
    return hexDigits.codeUnitAt(random.nextInt(16));
  });
  return String.fromCharCodes(chars);
}
