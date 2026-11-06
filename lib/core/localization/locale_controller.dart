import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/localization/app_language.dart';
import 'package:customer_app/core/managers/providers.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  () => LocaleController(),
);

class LocaleController extends Notifier<Locale> {
  static const String _localeKey = 'selected_locale';

  @override
  Locale build() {
    // Mirror every change for context-free code (error text, fallbacks).
    listenSelf((_, next) => AppLanguage.code = next.languageCode);
    // The saved choice, read now: the app's language and what is sent to the
    // backend on launch (push notifications) come from this first value.
    // Setting it afterwards was overwritten by the 'th' returned here, so
    // every launch reported Thai.
    final saved = ref.read(sharedPreferencesProvider).getString(_localeKey);
    final locale = Locale((saved == null || saved.isEmpty) ? 'th' : saved);
    AppLanguage.code = locale.languageCode;
    return locale;
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
