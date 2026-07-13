/// Compile-time feature flags for staged rollout of unfinished features.
///
/// Flip a flag to `true` to re-enable the feature once its backend/flows are
/// ready; keep the guarded UI wired so turning it back on needs no rework.
abstract class FeatureFlags {
  /// Cash-on-delivery (COD) for messenger parcels.
  ///
  /// Hidden for now: the "how much does the recipient pay?" collection and
  /// driver-wallet settlement side isn't finalised in the app yet. While off,
  /// the messenger booking screen omits the COD payment option and its amount
  /// field; only CASH / PromptPay remain.
  static const bool messengerCodEnabled = false;

  // ─── Food delivery ─────────────────────────────────────────────────────────
  // These gate UI that has no backing API yet (SCRUM-44 audit). Flip on once
  // the matching endpoint/field exists.

  /// Hardcoded promo sections on the home screen ("เมนูลด 60%", "ร้านยอดนิยม",
  /// promo banners). They render fake restaurants with placeholder ids, so
  /// tapping opens a detail page that doesn't exist — hidden until wired to the
  /// discovery feed.
  static const bool foodHomePromoSections = false;

  /// Extra controls on the food review screen — the driver rating/tags and the
  /// tip selector. The review API only accepts a single `rating` + `comment`,
  /// so these are never submitted (the "tip will be deducted" copy is false).
  static const bool foodReviewDriverExtras = false;

  /// The pickup / dine-in tabs on the food-delivery screen. The backend is
  /// delivery-only; the tabs never filter the feed. Delivery stays visible.
  static const bool foodPickupDineInTabs = false;

  /// The "สำหรับคุณ / For You" strip on the restaurant screen. No recommendation
  /// endpoint — it's faked from the first few menu items.
  static const bool foodForYouStrip = false;

  /// The coupon "เก็บ / collect" button. There is no clip-to-account endpoint;
  /// coupons only validate at checkout.
  static const bool foodCouponCollect = false;

  /// The "ขอช้อนส้อม / want cutlery" toggle at checkout. Not sent in the order
  /// body (no field for it).
  static const bool foodCutleryToggle = false;

  /// Decorative hardcoded promo banners on the food-delivery screen
  /// (quick-promos band, floating bottom banner). No provider behind them.
  static const bool foodPromoBanners = false;
}
