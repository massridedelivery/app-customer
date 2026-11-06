import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shared styling for promotions: the colour (by the service a promo is
/// for, see [PromoServiceColor]) and the headline ("ลด ฿100" / "ลด 20%" /
/// "ส่งฟรี", from `promo_type`, falling back to `discount_type` for payloads
/// without it; free shipping is a 100% delivery discount in the pricing
/// engine, so it's keyed off `promo_type`).

String _type(Map<String, dynamic> promo) =>
    (promo['promo_type'] ?? promo['discount_type'] ?? '')
        .toString()
        .toLowerCase();

/// Free delivery's own colour (teal), whatever its scope.
const Color kFreeDeliveryColor = Color(0xFF13A08F);
const Color kFreeDeliveryDarkColor = Color(0xFF0B7568);

/// The one promo colour scheme of the app, by the service a promo is for —
/// the same everywhere a promo appears (promo lists, coupon pickers, the home
/// "โปรโมชั่นสำหรับคุณ" cards, the promo detail, service-card badges):
/// เรียกรถ and ทุกบริการ red, ส่งอาหาร orange, ส่งของ blue; free delivery
/// teal.
extension PromoServiceColor on PromoScope {
  Color get serviceColor => switch (this) {
    PromoScope.ride || PromoScope.all => const Color(0xFFC8323F),
    PromoScope.food => const Color(0xFFE2855A),
    PromoScope.messenger => const Color(0xFF2F6FD6),
  };

  /// Darker shade for text / links in that colour.
  Color get serviceDarkColor => switch (this) {
    PromoScope.ride || PromoScope.all => const Color(0xFFB4313F),
    PromoScope.food => const Color(0xFFB5561F),
    PromoScope.messenger => const Color(0xFF1F55B0),
  };
}

/// The colour of [promo]: teal for free delivery, otherwise its service's
/// colour (see [PromoServiceColor]).
Color promoColorOf(Map<String, dynamic> promo) =>
    _type(promo) == 'free_shipping'
    ? kFreeDeliveryColor
    : promoScopeOf(promo).serviceColor;

/// Headline shown large on the card, in the UI language: "ลด ฿100" /
/// "ลด 20%" / "ส่งฟรี" (English: "฿100 off" / "20% off" / "Free Delivery").
String promoHeadlineOf(
  Map<String, dynamic> promo,
  AppLocalizations l10n, {
  String? fallback,
}) {
  if (_type(promo) == 'free_shipping') return l10n.freeDelivery;
  final raw = promo['discount_value'] ?? promo['discount'] ?? 0;
  final num value = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
  if (value <= 0) return fallback ?? l10n.promoHeadlineFallback;
  if (_type(promo) == 'percentage') {
    return l10n.promoHeadlinePercent(value.toStringAsFixed(0));
  }
  return l10n.promoHeadlineBaht(value.toStringAsFixed(0));
}

num _discountValueOf(Map<String, dynamic> promo) {
  if (_type(promo) == 'free_shipping') return 1 << 20; // rank free shipping high
  final raw = promo['discount_value'] ?? promo['discount'] ?? 0;
  return raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
}

/// True when [promo] applies to [serviceKey] ('ride' | 'food' | 'messenger').
///
/// Keys off the backend's `applies_to` ("ALL" | "RIDE" | "FOOD" | "MESSENGER";
/// see promo.Promotion), which the promo list already returns. Falls back to a
/// structured `service`/`services` field, then to keyword-matching
/// `tag`/`sub_tag`/`title`, only for payloads that don't carry `applies_to`.
bool promoAppliesToService(Map<String, dynamic> promo, String serviceKey) {
  final key = serviceKey.toLowerCase();

  // 0) Free delivery is a food-only perk — rides and messenger only get
  // discounts — so never offer it there, even when the backend scopes it ALL.
  if (_type(promo) == 'free_shipping') return key == 'food';

  // 1) Primary: the backend's `applies_to`. When present it is authoritative —
  // a promo scoped to another service must NOT fall through to a keyword guess.
  final appliesTo = (promo['applies_to'] ?? '').toString().toUpperCase();
  if (appliesTo.isNotEmpty) {
    return appliesTo == 'ALL' || appliesTo == key.toUpperCase();
  }

  // 2) Structured service field, for any other payload shape.
  final single =
      (promo['service'] ?? promo['service_type'] ?? '').toString().toLowerCase();
  if (single.isNotEmpty) {
    if (single == 'all') return true;
    if (single.split(RegExp(r'[,\s]+')).contains(key)) return true;
  }
  final many = promo['services'];
  if (many is List &&
      many.map((e) => e.toString().toLowerCase()).contains(key)) {
    return true;
  }

  // 3) Keyword fallback on human-readable fields.
  final hay =
      '${promo['tag'] ?? ''} ${promo['sub_tag'] ?? ''} ${promo['title'] ?? ''}'
          .toLowerCase();
  switch (key) {
    case 'ride':
      return hay.contains('ride') ||
          hay.contains('เดินทาง') ||
          hay.contains('เรียกรถ') ||
          hay.contains('โดยสาร');
    case 'food':
      return hay.contains('food') ||
          hay.contains('อาหาร') ||
          hay.contains('ร้านอาหาร');
    case 'messenger':
      return hay.contains('messenger') ||
          hay.contains('ส่งของ') ||
          hay.contains('พัสดุ') ||
          hay.contains('delivery');
  }
  return false;
}

/// The strongest active promo badge for a home service card, or `null` when the
/// customer has no promo for that service — so the card renders no badge.
///
/// [serviceKey] is 'ride' | 'food' | 'messenger'. The returned [text] carries a
/// trailing `*` ("เงื่อนไขเป็นไปตามที่กำหนด"), matching the card style.
({String text, Color color})? serviceBadgeOf(
  List<Map<String, dynamic>> promos,
  String serviceKey,
  AppLocalizations l10n,
) {
  final matched =
      promos.where((p) => promoAppliesToService(p, serviceKey)).toList();
  if (matched.isEmpty) return null;
  // Show the best offer: free shipping first, then the largest discount.
  matched.sort((a, b) => _discountValueOf(b).compareTo(_discountValueOf(a)));
  final best = matched.first;
  return (text: '${promoHeadlineOf(best, l10n)}*', color: promoColorOf(best));
}

/// Which service a promo can be used on, from the backend's `applies_to`
/// ("ALL" | "RIDE" | "FOOD" | "MESSENGER"). Shown as a text-only label on the
/// promo cards and used to filter the "โปรโมชั่นของฉัน" list.
enum PromoScope {
  // Pill text / tint in the service colours (see [PromoServiceColor]).
  all(Color(0xFFB4313F), Color(0xFFFBECEE)),
  ride(Color(0xFFB4313F), Color(0xFFFBECEE)),
  food(Color(0xFFB5561F), Color(0xFFFCEEE6)),
  messenger(Color(0xFF1F55B0), Color(0xFFE8F0FC));

  const PromoScope(this.foreground, this.background);

  final Color foreground;
  final Color background;

  /// Card label in the UI language, e.g. "เฉพาะเรียกรถ" / "Rides only".
  String label(AppLocalizations l10n) => switch (this) {
        PromoScope.all => l10n.promoScopeAll,
        PromoScope.ride => l10n.promoScopeRide,
        PromoScope.food => l10n.promoScopeFood,
        PromoScope.messenger => l10n.promoScopeMessenger,
      };

  /// Short name for a filter tab, e.g. "เรียกรถ" / "Ride".
  String tabLabel(AppLocalizations l10n) => switch (this) {
        PromoScope.all => l10n.promoTabGeneral,
        PromoScope.ride => l10n.promoTabRide,
        PromoScope.food => l10n.food,
        PromoScope.messenger => l10n.promoTabMessenger,
      };

  /// Parses an `applies_to` value. Missing or unknown values count as
  /// [PromoScope.all] — the backend's default scope.
  static PromoScope fromAppliesTo(Object? raw) =>
      switch ((raw ?? '').toString().trim().toUpperCase()) {
        'RIDE' => PromoScope.ride,
        'FOOD' => PromoScope.food,
        'MESSENGER' => PromoScope.messenger,
        _ => PromoScope.all,
      };
}

/// The service scope of [promo] (see [PromoScope]). Free delivery is always
/// food-only (see [promoAppliesToService]), whatever `applies_to` says.
PromoScope promoScopeOf(Map<String, dynamic> promo) =>
    _type(promo) == 'free_shipping'
        ? PromoScope.food
        : PromoScope.fromAppliesTo(promo['applies_to']);
