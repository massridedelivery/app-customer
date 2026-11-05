import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown only if the API is unreachable — the real number is admin-managed
/// server-side, so never hardcode it in the UI; this is just a safety net.
const String kSupportPhoneFallback = '065-6924555';

/// `GET /api/config/support` (public, no auth; admin-editable): the call
/// center number and which parts of in-app support are switched on.
class SupportConfig {
  const SupportConfig({
    this.phone = kSupportPhoneFallback,
    this.ticketsEnabled = false,
    this.chatEnabled = false,
  });

  final String phone;

  /// Step 1: "แจ้งปัญหา" and the customer's report history.
  final bool ticketsEnabled;

  /// Step 2: a report is a live chat with the team, and "แชทกับเจ้าหน้าที่"
  /// starts one. Only on together with [ticketsEnabled].
  final bool chatEnabled;

  factory SupportConfig.fromJson(Object? data) {
    if (data is! Map) return const SupportConfig();
    final phone = data['support_phone'];
    final tickets = data['support_tickets_enabled'] == true;
    return SupportConfig(
      phone: phone is String && phone.trim().isNotEmpty
          ? phone.trim()
          : kSupportPhoneFallback,
      ticketsEnabled: tickets,
      chatEnabled: tickets && data['support_chat_enabled'] == true,
    );
  }
}

/// Fetched at runtime (and again whenever the app comes back to the
/// foreground) so a change in admin takes effect without an app release. Any
/// error gives the fallback number with both support features off, so the
/// app never offers a form the backend may refuse.
final supportConfigProvider = FutureProvider<SupportConfig>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final res = await api.dio.get('/api/config/support');
    return SupportConfig.fromJson(res.data);
  } catch (_) {
    return const SupportConfig();
  }
});

/// Customer-support / call-center phone; [kSupportPhoneFallback] when the
/// config can't be read, so the call affordance always works.
final supportPhoneProvider = FutureProvider<String>(
  (ref) async => (await ref.watch(supportConfigProvider.future)).phone,
);

/// The switches as they stand now (off until the config has loaded).
final supportFlagsProvider = Provider<SupportConfig>(
  (ref) => ref.watch(supportConfigProvider).value ?? const SupportConfig(),
);
