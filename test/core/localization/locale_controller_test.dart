import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(p)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('the saved language is there from the first read', () async {
    final c = await _container({'selected_locale': 'en'});
    expect(c.read(localeControllerProvider).languageCode, 'en');
  });

  test('nothing saved: Thai', () async {
    final c = await _container({});
    expect(c.read(localeControllerProvider).languageCode, 'th');
  });

  test('a change is saved for the next launch', () async {
    final c = await _container({});
    await c
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('en'));
    final again = await _container({'selected_locale': 'en'});
    expect(c.read(localeControllerProvider).languageCode, 'en');
    expect(again.read(localeControllerProvider).languageCode, 'en');
  });
}
