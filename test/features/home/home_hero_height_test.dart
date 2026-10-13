import 'package:customer_app/features/home/presentation/screens/service_selection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// How far the home S-curve cuts up into the bottom of the header.
const double _waveCut = 38;

double _bandUnderSearch(double hero, double status) =>
    hero - status - kHomeSearchBarBottom;

void main() {
  final devices = <(String, TargetPlatform, double, double)>[
    // name, platform, status bar, logical screen height
    ('Galaxy A07', TargetPlatform.android, 24, 800),
    ('small Android', TargetPlatform.android, 24, 640),
    ('iPhone SE', TargetPlatform.iOS, 20, 667),
    ('iPhone 13/14', TargetPlatform.iOS, 47, 844),
    ('iPhone 15 Pro (Dynamic Island)', TargetPlatform.iOS, 59, 852),
    ('iPhone 15 Pro Max', TargetPlatform.iOS, 59, 932),
  ];

  for (final (name, platform, status, height) in devices) {
    test('$name: the wave stays clear of the search bar', () {
      final hero = homeHeroHeight(
        statusPadding: status,
        screenHeight: height,
        platform: platform,
      );
      final band = _bandUnderSearch(hero, status);
      expect(band, greaterThanOrEqualTo(56));
      expect(band - _waveCut, greaterThan(15),
          reason: 'at least 15px of red between the wave crest and the bar');
    });
  }

  test('the header grows with the status bar instead of a fixed height', () {
    final android = homeHeroHeight(
      statusPadding: 24,
      screenHeight: 852,
      platform: TargetPlatform.android,
    );
    final iphone = homeHeroHeight(
      statusPadding: 59,
      screenHeight: 852,
      platform: TargetPlatform.iOS,
    );
    expect(iphone, greaterThan(android));
  });
}
