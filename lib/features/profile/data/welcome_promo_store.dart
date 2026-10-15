import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The referral welcome code (e.g. FRIEND50) a new customer got by entering a
/// friend's code. Booking / messenger pre-fill it on the first order and clear
/// it once an order is placed with it.
class WelcomePromoStore {
  WelcomePromoStore(this._prefs);

  static const _key = 'referral_welcome_promo';
  final SharedPreferences _prefs;

  String? get code {
    final v = _prefs.getString(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> save(String code) => _prefs.setString(_key, code);

  /// Clears it when [usedCode] is the stored one (case-insensitive).
  Future<void> consume(String? usedCode) async {
    final stored = code;
    if (stored == null || usedCode == null) return;
    if (stored.toUpperCase() == usedCode.toUpperCase()) {
      await _prefs.remove(_key);
    }
  }
}

final welcomePromoStoreProvider = Provider<WelcomePromoStore>(
  (ref) => WelcomePromoStore(ref.watch(sharedPreferencesProvider)),
);
