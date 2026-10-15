import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The app's current UI language for code that runs without a BuildContext or
/// a Ref (error mappers, repositories, controllers' fallbacks).
///
/// [LocaleController] keeps [code] in sync with the language picked in
/// Profile → เปลี่ยนภาษา. Widgets should keep using
/// `AppLocalizations.of(context)` — this is only for context-free code.
class AppLanguage {
  AppLanguage._();

  /// Current language code ('th' | 'en'). Thai until the saved choice loads.
  static String code = 'th';

  /// True when the UI is in Thai (or [languageCode], when given, is Thai).
  static bool isThai([String? languageCode]) =>
      _supported(languageCode ?? code) == 'th';

  /// Strings for the current language, or for [languageCode] when given.
  /// An unsupported code falls back to Thai.
  static AppLocalizations l10n([String? languageCode]) =>
      lookupAppLocalizations(Locale(_supported(languageCode ?? code)));

  static String _supported(String c) => c == 'en' ? 'en' : 'th';
}
