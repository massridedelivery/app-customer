/// The promo / points parts of a ride estimate and booking
/// (BE docs/referral_points.md §3.1–3.2).
library;

double _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// What the code in the promo box did to this vehicle's fare. Present when a
/// `promo_code` was sent; a refused code is `applied: false` with a reason —
/// the estimate itself never fails because of a code.
class RidePromoQuote {
  const RidePromoQuote({
    required this.code,
    required this.applied,
    this.discount = 0,
    this.kind = 'PROMO',
    this.label,
    this.errorCode,
    this.error,
  });

  final String code;
  final bool applied;
  final double discount;

  /// PROMO | REFERRAL | VOUCHER.
  final String kind;

  /// "โค้ดเพื่อน" / "คูปองแลกคะแนน" (null for ordinary promos).
  final String? label;

  /// Referral / voucher refusals only (e.g. REFERRAL_OWN_CODE).
  final String? errorCode;

  /// Thai for referral / voucher refusals; English engine text for promos.
  final String? error;

  static RidePromoQuote? fromJson(Object? json) {
    if (json is! Map) return null;
    return RidePromoQuote(
      code: _str(json['code']) ?? '',
      applied: json['applied'] == true,
      discount: _double(json['discount']),
      kind: (_str(json['kind']) ?? 'PROMO').toUpperCase(),
      label: _str(json['label']),
      errorCode: _str(json['error_code']),
      error: _str(json['error']),
    );
  }
}

/// Paying with points on this vehicle: what's available and what's used.
class RidePointsQuote {
  const RidePointsQuote({
    this.enabled = false,
    this.balance = 0,
    this.bahtPerPoint = 1,
    this.minRedeem = 1,
    this.maxUsablePoints = 0,
    this.usedPoints = 0,
    this.discount = 0,
    this.reasonUnavailable,
    this.totalAfterPoints,
    this.errorCode,
    this.error,
  });

  final bool enabled;
  final int balance;
  final double bahtPerPoint;
  final int minRedeem;
  final int maxUsablePoints;
  final int usedPoints;
  final double discount;

  /// Why points can't be used: DISABLED | GUEST | NO_POINTS | BELOW_MIN |
  /// NOTHING_TO_PAY, or null when they can.
  final String? reasonUnavailable;
  final double? totalAfterPoints;

  /// A `points_to_use` too large for this vehicle (estimate without a
  /// vehicle_type_id reports it here instead of failing).
  final String? errorCode;
  final String? error;

  /// The row is hidden (switched off by the admin).
  bool get hidden => !enabled || reasonUnavailable == 'DISABLED';

  bool get usable => !hidden && reasonUnavailable == null;

  static RidePointsQuote? fromJson(Object? json) {
    if (json is! Map) return null;
    return RidePointsQuote(
      enabled: json['enabled'] == true,
      balance: _int(json['balance']),
      bahtPerPoint: json['baht_per_point'] == null
          ? 1
          : _double(json['baht_per_point']),
      minRedeem: json['min_redeem'] == null ? 1 : _int(json['min_redeem']),
      maxUsablePoints: _int(json['max_usable_points']),
      usedPoints: _int(json['used_points']),
      discount: _double(json['discount']),
      reasonUnavailable: _str(json['reason_unavailable'])?.toUpperCase(),
      totalAfterPoints: json['total_after_points'] == null
          ? null
          : _double(json['total_after_points']),
      errorCode: _str(json['error_code']),
      error: _str(json['error']),
    );
  }
}

/// `POST /api/customer/jobs` 201: the job id plus what the booking took.
class RideBooking {
  const RideBooking({
    required this.id,
    this.amountDue,
    this.pointsUsed = 0,
    this.promo,
  });

  final String id;
  final double? amountDue;
  final int pointsUsed;
  final RidePromoQuote? promo;

  factory RideBooking.fromJson(Map<String, dynamic> json) => RideBooking(
    id: json['id']?.toString() ?? '',
    amountDue: json['amount_due'] == null ? null : _double(json['amount_due']),
    pointsUsed: _int(json['points_used']),
    promo: RidePromoQuote.fromJson(json['promo']),
  );
}
