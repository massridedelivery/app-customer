import 'dart:math';

import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A random per-install id, created once and kept in SharedPreferences. Sent
/// as `device_id` where the backend rate-limits per device (email OTP).
final installIdProvider = Provider<String>((ref) {
  const key = 'install_id';
  final prefs = ref.watch(sharedPreferencesProvider);
  final existing = prefs.getString(key);
  if (existing != null && existing.isNotEmpty) return existing;
  final rnd = Random.secure();
  final id = List.generate(16, (_) => rnd.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  prefs.setString(key, id);
  return id;
});
