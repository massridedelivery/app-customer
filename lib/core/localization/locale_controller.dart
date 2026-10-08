import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/managers/providers.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  () => LocaleController(),
);

class LocaleController extends Notifier<Locale> {
  static const String _localeKey = 'selected_locale';

  @override
  Locale build() {
    // Standard build method for Notifier
    _initLocale();
    return const Locale('th');
  }

  Future<void> _initLocale() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale googleLocale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, googleLocale.languageCode);
    state = googleLocale;
    // Push the choice to the backend so push notifications match. Best-effort:
    // switching language must never fail on a network/auth hiccup, and a guest
    // (no token) simply syncs it after logging in.
    if (ref.read(tokenStorageProvider).hasToken) {
      unawaited(
        ref
            .read(apiRepositoryProvider)
            .updateLanguage(googleLocale.languageCode)
            .catchError((_) {}),
      );
    }
  }
}
