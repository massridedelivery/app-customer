import 'package:flutter/material.dart';

/// Shared styling for promotion cards/banners (home Style-B card + detail),
/// derived from the backend `promo_type` so the three promo kinds get a
/// consistent brand color and headline without the admin having to pick a color.
///
/// - `fixed`         → red,    "ลด ฿{value}"
/// - `percentage`    → orange, "ลด {value}%"
/// - `free_shipping` → green,  "ส่งฟรี"  (value not shown)
///
/// `promo_type` is the display kind and is distinct from `discount_type`, which
/// the pricing engine uses to compute money (free shipping is a 100% discount on
/// delivery, i.e. discount_type "percentage"). We key the card styling off
/// `promo_type`, falling back to `discount_type` only for pre-rollout payloads
/// that don't carry it yet. An unknown type falls back to the red/`fixed` look.
///
/// An explicit `color` on the promo (ARGB int) overrides the type color.

const Color _promoRed = Color(0xFFC0343E);
const Color _promoOrange = Color(0xFFE08A00);
const Color _promoGreen = Color(0xFF1E9E63);

String _type(Map<String, dynamic> promo) =>
    (promo['promo_type'] ?? promo['discount_type'] ?? '')
        .toString()
        .toLowerCase();

/// Card color: the admin-set `color` (64-bit ARGB int) if present, otherwise a
/// brand color chosen by `discount_type`.
Color promoColorOf(Map<String, dynamic> promo) {
  final override = (promo['color'] as num?)?.toInt();
  if (override != null) return Color(override);
  switch (_type(promo)) {
    case 'percentage':
      return _promoOrange;
    case 'free_shipping':
      return _promoGreen;
    default:
      return _promoRed;
  }
}

/// Headline shown large on the card: "ลด ฿100" / "ลด 20%" / "ส่งฟรี".
String promoHeadlineOf(Map<String, dynamic> promo, {String? fallback}) {
  if (_type(promo) == 'free_shipping') return 'ส่งฟรี';
  final raw = promo['discount_value'] ?? promo['discount'] ?? 0;
  final num value = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
  if (value <= 0) return fallback ?? 'โปรโมชัน';
  if (_type(promo) == 'percentage') return 'ลด ${value.toStringAsFixed(0)}%';
  return 'ลด ฿${value.toStringAsFixed(0)}';
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
) {
  final matched =
      promos.where((p) => promoAppliesToService(p, serviceKey)).toList();
  if (matched.isEmpty) return null;
  // Show the best offer: free shipping first, then the largest discount.
  matched.sort((a, b) => _discountValueOf(b).compareTo(_discountValueOf(a)));
  final best = matched.first;
  return (text: '${promoHeadlineOf(best)}*', color: promoColorOf(best));
}
