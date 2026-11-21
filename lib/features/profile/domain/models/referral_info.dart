/// `GET /api/customer/loyalty/referral` (BE #194). Every number comes from
/// the backend (admin-tunable) — the app never hardcodes rewards.
class ReferralInfo {
  const ReferralInfo({
    required this.enabled,
    this.code,
    this.maxUses,
    this.currentUses = 0,
    this.referrerRewardPoints = 0,
    this.friendRewardCode,
    this.friendRewardValue = 0,
    this.stats = const ReferralStats(),
    this.canApplyCode = false,
    this.applyBefore,
    this.referredByStatus,
    this.referredByWelcomeCode,
    this.referredByCode,
    this.referredByWelcomeValue = 0,
    this.shareMessage,
    this.friends = const [],
    this.tiers = const [],
    this.friendsCounted = 0,
  });

  /// Coupon milestones (e.g. 1 friend → ฿20, 5 → ฿75), set by the admin;
  /// empty when there are none. On top of the points per friend.
  final List<ReferralTier> tiers;

  /// Friends who completed a first order: what the [tiers] count.
  final int friendsCounted;

  /// The first milestone not reached yet; null when there are none left.
  ReferralTier? get nextTier {
    for (final t in tiers) {
      if (!t.reached) return t;
    }
    return null;
  }

  /// Friends still to bring for [nextTier] (at least 1).
  int get friendsToNextTier {
    final next = nextTier;
    if (next == null) return 0;
    final left = next.friends - friendsCounted;
    return left < 1 ? 1 : left;
  }

  /// Ready-made share text from the backend ("ใช้โค้ด K7QM2X ลด ฿50 …").
  final String? shareMessage;

  /// Friends who used the code, names masked by the backend.
  final List<ReferralFriend> friends;

  /// False hides the referral menu and page.
  final bool enabled;

  /// The user's own code (the backend creates it on first GET).
  final String? code;
  final int? maxUses;
  final int currentUses;

  /// Points the user gets when a friend completes their first order.
  final int referrerRewardPoints;

  /// The welcome promo a friend gets (e.g. FRIEND50 / ฿50).
  final String? friendRewardCode;
  final double friendRewardValue;

  final ReferralStats stats;

  /// A new customer may still enter someone's code.
  final bool canApplyCode;
  final DateTime? applyBefore;

  /// Set once this user entered a code; "PENDING" until their first order.
  final String? referredByStatus;
  final String? referredByWelcomeCode;

  /// The friend's code this user signed up with ("คุณสมัครด้วยรหัส …").
  final String? referredByCode;
  final double referredByWelcomeValue;

  /// Every friend slot on the user's own code is taken.
  bool get codeFull => maxUses != null && maxUses! > 0 && currentUses >= maxUses!;

  bool get wasReferred => referredByStatus != null;
  bool get welcomePromoPending =>
      referredByStatus?.toUpperCase() == 'PENDING' &&
      (referredByWelcomeCode?.isNotEmpty ?? false);

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? v) =>
        v is Map ? Map<String, dynamic>.from(v) : const {};
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    double asDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    String? asString(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final codeJson = map(json['referral_code']);
    final friend = map(json['friend_reward']);
    final referredBy = json['referred_by'] is Map
        ? map(json['referred_by'])
        : null;
    final welcome = map(referredBy?['welcome_promo']);
    return ReferralInfo(
      enabled: json['enabled'] != false,
      code: asString(codeJson['code']),
      maxUses: codeJson['max_uses'] == null ? null : asInt(codeJson['max_uses']),
      currentUses: asInt(codeJson['current_uses']),
      referrerRewardPoints: asInt(
        json['referrer_points'] ?? json['referrer_reward_points'],
      ),
      friendRewardCode: asString(friend['code']),
      friendRewardValue: asDouble(
        json['referee_discount_baht'] ?? friend['discount_value'],
      ),
      shareMessage: asString(json['share_message']),
      friends: json['friends'] is List
          ? (json['friends'] as List)
                .whereType<Map>()
                .map((m) => ReferralFriend.fromJson(map(m)))
                .toList()
          : const [],
      stats: ReferralStats.fromJson(map(json['stats'])),
      tiers: json['tiers'] is List
          ? (json['tiers'] as List)
                .whereType<Map>()
                .map((m) => ReferralTier.fromJson(map(m)))
                .where((t) => t.friends > 0)
                .toList()
          : const [],
      friendsCounted: asInt(json['friends_counted']),
      canApplyCode: json['can_apply_code'] == true,
      applyBefore: DateTime.tryParse('${json['apply_before'] ?? ''}'),
      referredByStatus: referredBy == null
          ? null
          : (asString(referredBy['status']) ?? 'APPLIED'),
      referredByWelcomeCode: asString(welcome['code']),
      referredByCode: asString(referredBy?['code']),
      referredByWelcomeValue: asDouble(welcome['discount_value']),
    );
  }
}

class ReferralStats {
  const ReferralStats({
    this.totalReferrals = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.totalRewardPoints = 0,
    this.pendingRewardPoints = 0,
  });

  final int totalReferrals;
  final int completedCount;
  final int pendingCount;
  final int totalRewardPoints;
  final int pendingRewardPoints;

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return ReferralStats(
      totalReferrals: asInt(json['invited'] ?? json['total_referrals']),
      completedCount: asInt(json['completed'] ?? json['completed_count']),
      pendingCount: asInt(json['pending_count']),
      totalRewardPoints: asInt(
        json['points_earned'] ?? json['total_reward_points'],
      ),
      pendingRewardPoints: asInt(json['pending_reward_points']),
    );
  }
}

/// One friend on the referral list.
class ReferralFriend {
  const ReferralFriend({
    required this.name,
    required this.status,
    this.points = 0,
    this.createdAt,
    this.rewardedAt,
  });

  final String name;

  /// PENDING (first trip not done yet) | REWARDED | CANCELLED.
  final String status;

  /// The points this friend is worth (earned once REWARDED).
  final int points;
  final DateTime? createdAt;
  final DateTime? rewardedAt;

  factory ReferralFriend.fromJson(Map<String, dynamic> json) => ReferralFriend(
    name: json['name']?.toString() ?? '',
    status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
    points: json['points'] is num ? (json['points'] as num).toInt() : 0,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    rewardedAt: DateTime.tryParse('${json['rewarded_at'] ?? ''}'),
  );
}

/// One coupon milestone of `tiers` (backend referral TierProgress:
/// friends, amount, reached, voucher_code).
class ReferralTier {
  const ReferralTier({
    required this.friends,
    required this.amount,
    this.reached = false,
    this.voucherCode,
  });

  /// Friends to bring for it.
  final int friends;

  /// The coupon, in baht.
  final double amount;
  final bool reached;

  /// The coupon issued for it, once issued (in the customer's vouchers).
  final String? voucherCode;

  factory ReferralTier.fromJson(Map<String, dynamic> json) {
    final code = json['voucher_code']?.toString().trim();
    final amount = json['amount'];
    final friends = json['friends'];
    return ReferralTier(
      friends: friends is num ? friends.toInt() : int.tryParse('$friends') ?? 0,
      amount: amount is num
          ? amount.toDouble()
          : double.tryParse('$amount') ?? 0,
      reached: json['reached'] == true,
      voucherCode: code == null || code.isEmpty ? null : code,
    );
  }
}
