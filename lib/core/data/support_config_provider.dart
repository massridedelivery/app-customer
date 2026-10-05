import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown only if the API is unreachable — the real number is admin-managed
/// server-side, so never hardcode it in the UI; this is just a safety net.
const String kSupportPhoneFallback = '065-6924555';

/// Customer-support / call-center phone from `GET /api/config/support`
/// (public, no auth; admin-editable). Fetched at runtime so a number change in
/// admin takes effect without an app release. Falls back to
/// [kSupportPhoneFallback] on any error so the call affordance always works.
final supportPhoneProvider = FutureProvider<String>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final res = await api.dio.get('/api/config/support');
    final data = res.data;
    if (data is Map &&
        data['support_phone'] is String &&
        (data['support_phone'] as String).trim().isNotEmpty) {
      return (data['support_phone'] as String).trim();
    }
  } catch (_) {
    // Network/parse error — fall through to the safety-net number.
  }
  return kSupportPhoneFallback;
});
