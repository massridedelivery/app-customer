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
