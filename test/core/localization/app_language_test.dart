import 'package:customer_app/core/localization/app_language.dart';
import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppLanguage.code = 'th');

  test('defaults to Thai; unsupported codes fall back to Thai', () {
    expect(AppLanguage.isThai(), isTrue);
    expect(AppLanguage.l10n().errGeneric, 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    expect(AppLanguage.l10n('fr').errGeneric, 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    expect(
      AppLanguage.l10n('en').errGeneric,
      'Something went wrong. Please try again.',
    );
  });

  test('follows the locale controller', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final controller = container.read(localeControllerProvider.notifier);
    container.listen(localeControllerProvider, (_, _) {});
    await controller.setLocale(const Locale('en'));
    expect(container.read(localeControllerProvider).languageCode, 'en');
    expect(AppLanguage.code, 'en');
    expect(AppLanguage.isThai(), isFalse);

    await controller.setLocale(const Locale('th'));
    expect(AppLanguage.code, 'th');
  });
}
