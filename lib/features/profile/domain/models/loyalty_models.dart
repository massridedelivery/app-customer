/// Points, rewards and vouchers (BE docs/referral_points.md, point_rewards.md).
/// Every rule number (points per baht, costs, limits) comes from the API —
/// admins change them at any time, so the app never hardcodes one.
library;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
int? _intOrNull(Object? v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
double _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _date(Object? v) => DateTime.tryParse('${v ?? ''}');
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

/// `GET /api/customer/loyalty/summary`.
class LoyaltySummary {
  const LoyaltySummary({
    this.totalPoints = 0,
    this.lifetimePoints = 0,
    this.pointsEnabled = true,
    this.bahtPerPoint = 1,
    this.balanceBaht = 0,
    this.expiringPoints = 0,
    this.expiringAt,
    this.earnPer100Ride = 0,
    this.earnMinOrder = 0,
  });

  final int totalPoints;
  final int lifetimePoints;

  /// False: points are switched off — banner, no redeeming, no points row.
  final bool pointsEnabled;
  final double bahtPerPoint;
  final double balanceBaht;

  /// Points in lots that expire within 30 days, and the soonest expiry.
  final int expiringPoints;
  final DateTime? expiringAt;

  /// Points per ฿100 paid on a ride, and the minimum order that earns any.
  final int earnPer100Ride;
  final double earnMinOrder;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final points = _map(json['points']);
    final expiring = _map(json['expiring_soon']);
    final earn = _map(json['earn_per_100_baht']);
    return LoyaltySummary(
      totalPoints: _int(points['total_points']),
      lifetimePoints: _int(points['lifetime_points']),
      pointsEnabled: json['points_enabled'] != false,
      bahtPerPoint: json['points_baht_value'] == null
          ? 1
          : _double(json['points_baht_value']),
      balanceBaht: _double(json['balance_baht']),
      expiringPoints: _int(expiring['points']),
      expiringAt: _date(expiring['expires_at']),
      earnPer100Ride: _int(earn['ride']),
      earnMinOrder: _double(earn['min_order']),
    );
  }
}

/// One row of `GET /api/customer/loyalty/points` (REDEEM rows are negative).
class PointsEntry {
  const PointsEntry({
    required this.id,
    required this.type,
    required this.points,
    this.description = '',
    this.orderType,
    this.createdAt,
    this.expiresAt,
  });

  final String id;

  /// EARN | REDEEM | REFUND | EXPIRE | ADJUST.
  final String type;
  final int points;
  final String description;

  /// RIDE | FOOD | PARCEL | REFERRAL, or null.
  final String? orderType;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory PointsEntry.fromJson(Map<String, dynamic> json) => PointsEntry(
    id: json['id']?.toString() ?? '',
    type: (_str(json['type']) ?? '').toUpperCase(),
    points: _int(json['points']),
    description: _str(json['description']) ?? '',
    orderType: _str(json['order_type'])?.toUpperCase(),
    createdAt: _date(json['created_at']),
    expiresAt: _date(json['expires_at']),
  );
}

/// One reward in `GET /api/customer/rewards`.
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.pointsCost,
    this.description = '',
    this.terms = '',
    this.imageUrl,
    this.discountText = '',
    this.appliesTo = 'ALL',
    this.stockLeft,
    this.canRedeem = false,
    this.reason,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String description;

  /// Conditions, one per line (`\n`).
  final String terms;
  final String? imageUrl;
  final int pointsCost;

  /// Ready-made one-liner ("ลด ฿30 ค่าเรียกรถ"), shown as is.
  final String discountText;

  /// RIDE | FOOD | MESSENGER | ALL.
  final String appliesTo;

  /// Units left; null = unlimited.
  final int? stockLeft;
  final bool canRedeem;

  /// Why not, when [canRedeem] is false: POINTS_DISABLED, NOT_STARTED, ENDED,
  /// OUT_OF_STOCK, LIMIT_REACHED or INSUFFICIENT_POINTS.
  final String? reason;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id']?.toString() ?? '',
    title: _str(json['title']) ?? '',
    description: _str(json['description']) ?? '',
    terms: _str(json['terms']) ?? '',
    imageUrl: _str(json['image_url']),
    pointsCost: _int(json['points_cost']),
    discountText: _str(json['discount_text']) ?? '',
    appliesTo: (_str(json['applies_to']) ?? 'ALL').toUpperCase(),
    stockLeft: _intOrNull(json['stock_left']),
    canRedeem: json['can_redeem'] == true,
    reason: _str(json['reason'])?.toUpperCase(),
    startsAt: _date(json['starts_at']),
    endsAt: _date(json['ends_at']),
  );
}

class RewardList {
  const RewardList({
    this.pointsEnabled = true,
    this.pointsBalance = 0,
    this.items = const [],
  });

  final bool pointsEnabled;
  final int pointsBalance;
  final List<Reward> items;

  factory RewardList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return RewardList(
      pointsEnabled: json['points_enabled'] != false,
      pointsBalance: _int(json['points_balance']),
      items: raw is List
          ? raw.whereType<Map>().map((m) => Reward.fromJson(_map(m))).toList()
          : const [],
    );
  }
}

/// A voucher (`RW-XXXX-XXXX`) the customer got for points.
class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    this.discountText = '',
    this.appliesTo = 'ALL',
    this.status = 'ACTIVE',
    this.pointsSpent = 0,
    this.expiresAt,
    this.usedAt,
    this.usedOrderType,
  });

  final String id;
  final String code;
  final String title;
  final String discountText;

  /// RIDE | FOOD | MESSENGER | ALL.
  final String appliesTo;

  /// ACTIVE | USED | EXPIRED.
  final String status;
  final int pointsSpent;
  final DateTime? expiresAt;
  final DateTime? usedAt;

  /// RIDE | FOOD | MESSENGER once used.
  final String? usedOrderType;

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id']?.toString() ?? '',
    code: _str(json['code']) ?? '',
    title: _str(json['title']) ?? '',
    discountText: _str(json['discount_text']) ?? '',
    appliesTo: (_str(json['applies_to']) ?? 'ALL').toUpperCase(),
    status: (_str(json['status']) ?? 'ACTIVE').toUpperCase(),
    pointsSpent: _int(json['points_spent']),
    expiresAt: _date(json['expires_at']),
    usedAt: _date(json['used_at']),
    usedOrderType: _str(json['used_order_type'])?.toUpperCase(),
  );
}

/// `POST /api/customer/rewards/{id}/redeem` → the new voucher and balance.
class RedeemResult {
  const RedeemResult({
    required this.voucher,
    required this.pointsBalance,
    this.replayed = false,
  });

  final Voucher voucher;
  final int pointsBalance;

  /// The same Idempotency-Key was sent again: this is the first call's
  /// voucher, nothing was spent twice.
  final bool replayed;

  factory RedeemResult.fromJson(Map<String, dynamic> json) => RedeemResult(
    voucher: Voucher.fromJson(_map(json['voucher'])),
    pointsBalance: _int(json['points_balance']),
    replayed: json['replayed'] == true,
  );
}
