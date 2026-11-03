import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/widgets/driver_avatar.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String? url) => MaterialApp(
  home: Scaffold(
    body: Center(child: DriverAvatar(url: url)),
  ),
);

void main() {
  group('DriverAvatar.usableUrl', () {
    test('only a full URL is loaded', () {
      expect(DriverAvatar.usableUrl(null), isNull);
      expect(DriverAvatar.usableUrl(''), isNull);
      expect(DriverAvatar.usableUrl('   '), isNull);
      expect(
        DriverAvatar.usableUrl('avatar/d1/x.jpg'),
        isNull,
        reason: 'a bare media key is never joined to a host',
      );
      expect(
        DriverAvatar.usableUrl(' https://cdn.test/avatar/d1/x.jpg '),
        'https://cdn.test/avatar/d1/x.jpg',
      );
      expect(
        DriverAvatar.usableUrl('http://cdn.test/a.jpg'),
        'http://cdn.test/a.jpg',
      );
    });
  });

  group('DriverAvatar', () {
    for (final url in [null, '', 'avatar/d1/x.jpg']) {
      testWidgets('"$url" shows the placeholder', (tester) async {
        await tester.pumpWidget(_host(url));
        expect(
          find.byKey(const Key('driverAvatarPlaceholder')),
          findsOneWidget,
        );
        expect(find.byType(CachedNetworkImage), findsNothing);
      });
    }

    testWidgets('a full URL is loaded (cached by URL)', (tester) async {
      await tester.pumpWidget(_host('https://cdn.test/avatar/d1/x.jpg'));
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://cdn.test/avatar/d1/x.jpg');
      expect(image.useOldImageOnUrlChange, isTrue);
      // While loading (and on failure) the placeholder is what shows.
      expect(find.byKey(const Key('driverAvatarPlaceholder')), findsOneWidget);
    });
  });

  group('driver_info.avatar_url parsing', () {
    test('messenger: present, null, absent', () {
      MessengerOrder order(Map<String, dynamic>? info) =>
          MessengerOrder.fromJson({
            'id': 'm1',
            'driver_id': 'd1',
            'driver_info': ?info,
          });
      expect(order(null).driverInfo, isNull);
      expect(
        order({'full_name': 'สมชาย', 'avatar_url': null}).driverInfo?.avatarUrl,
        isNull,
      );
      final info = order({
        'full_name': 'สมชาย',
        'avatar_url': 'https://cdn.test/a.jpg',
        'rating': 4.8,
        'vehicle_plate': '1กข 1234',
        'vehicle_province': 'กรุงเทพมหานคร',
      }).driverInfo!;
      expect(info.fullName, 'สมชาย');
      expect(info.avatarUrl, 'https://cdn.test/a.jpg');
      expect(info.rating, 4.8);
      expect(info.vehicleProvince, 'กรุงเทพมหานคร');
    });

    test('food: avatar_url is read', () {
      expect(
        FoodDriverInfoModel.fromJson({
          'full_name': 'สมชาย',
          'avatar_url': 'https://cdn.test/a.jpg',
        }).avatarUrl,
        'https://cdn.test/a.jpg',
      );
      expect(
        FoodDriverInfoModel.fromJson({'full_name': 'x'}).avatarUrl,
        isNull,
      );
    });
  });
}
