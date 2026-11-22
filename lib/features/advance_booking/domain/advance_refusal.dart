import 'package:dio/dio.dart';

/// Why the backend refused an advance booking call: 422 `{code, error}` (plus
/// `title` / `message` for ADVANCE_DISABLED). The app branches on [kind],
/// never on the text.
enum AdvanceRefusalKind {
  disabled, // ADVANCE_DISABLED
  vehicleNotBookable, // VEHICLE_NOT_BOOKABLE
  tooSoon, // TOO_SOON
  tooFar, // TOO_FAR
  tooManyBookings, // TOO_MANY_BOOKINGS
  cashNotAllowed, // CASH_NOT_ALLOWED
  outstandingFees, // OUTSTANDING_FEES
  flightNumberInvalid, // FLIGHT_NUMBER_INVALID
  cannotReschedule, // CANNOT_RESCHEDULE
  tooManyReschedules, // TOO_MANY_RESCHEDULES
  areaNotCovered, // AREA_NOT_COVERED
  unknown,
}

class AdvanceRefusal implements Exception {
  const AdvanceRefusal(this.kind, {this.code = '', this.title, this.message});

  final AdvanceRefusalKind kind;
  final String code;

  /// The closed dialog's texts (ADVANCE_DISABLED only).
  final String? title;
  final String? message;

  static AdvanceRefusalKind kindOf(String code) => switch (code) {
    'ADVANCE_DISABLED' => AdvanceRefusalKind.disabled,
    'VEHICLE_NOT_BOOKABLE' => AdvanceRefusalKind.vehicleNotBookable,
    'TOO_SOON' => AdvanceRefusalKind.tooSoon,
    'TOO_FAR' => AdvanceRefusalKind.tooFar,
    'TOO_MANY_BOOKINGS' => AdvanceRefusalKind.tooManyBookings,
    'CASH_NOT_ALLOWED' => AdvanceRefusalKind.cashNotAllowed,
    'OUTSTANDING_FEES' => AdvanceRefusalKind.outstandingFees,
    'FLIGHT_NUMBER_INVALID' => AdvanceRefusalKind.flightNumberInvalid,
    'CANNOT_RESCHEDULE' => AdvanceRefusalKind.cannotReschedule,
    'TOO_MANY_RESCHEDULES' => AdvanceRefusalKind.tooManyReschedules,
    'AREA_NOT_COVERED' => AdvanceRefusalKind.areaNotCovered,
    _ => AdvanceRefusalKind.unknown,
  };

  /// The refusal in a 422 answer with a `code`; null for any other error.
  static AdvanceRefusal? from(Object error) {
    if (error is AdvanceRefusal) return error;
    if (error is! DioException) return null;
    final res = error.response;
    if (res?.statusCode != 422) return null;
    final data = res?.data;
    if (data is! Map) return null;
    final code = (data['code'] ?? '').toString();
    if (code.isEmpty) return null;
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return AdvanceRefusal(
      kindOf(code),
      code: code,
      title: text(data['title']),
      message: text(data['message']),
    );
  }

  /// Paying in the app would get past it.
  bool get needsInAppPayment =>
      kind == AdvanceRefusalKind.cashNotAllowed ||
      kind == AdvanceRefusalKind.outstandingFees;

  /// The time no longer fits: refresh the config and pick another.
  bool get needsNewTime =>
      kind == AdvanceRefusalKind.tooSoon || kind == AdvanceRefusalKind.tooFar;

  @override
  String toString() => 'AdvanceRefusal($code)';
}

/// Whether a pickup place reads like an airport, so the confirm screen offers
/// the flight number field (spec 1.6). The server checks the number itself.
bool looksLikeAirport(String? place) {
  final s = (place ?? '').toLowerCase();
  if (s.isEmpty) return false;
  const words = [
    'สนามบิน',
    'ท่าอากาศยาน',
    'airport',
    'suvarnabhumi',
    'don mueang',
    'donmueang',
    'สุวรรณภูมิ',
    'ดอนเมือง',
  ];
  return words.any(s.contains);
}
