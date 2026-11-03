import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_booking_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeController extends HomeController {
  @override
  HomeState build() => const HomeState(
    pickupLocation: LatLng(13.85, 100.5),
    dropoffLocation: LatLng(13.86, 100.51),
  );
}

/// DIS30 is used up for this customer: refused as the backend does (v1.6.16).
class _Repo implements IMessengerRepository {
  final asked = <String?>[];

  @override
  Future<List<MessengerVehicleType>> getMessengerVehicleTypes() async => const [
    MessengerVehicleType(
      id: 'bike',
      isActive: true,
      sizeTiers: [MessengerSizeTier(tier: 'S', maxWeightKg: 5)],
    ),
  ];

  @override
  Future<MessengerEstimate> estimate({
    required String vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String packageSizeTier,
    required double packageWeightKg,
    double? packageLengthCm,
    double? packageWidthCm,
    double? packageHeightCm,
    String? promoCode,
    String? deliveryType,
    bool usePoints = false,
  }) async {
    asked.add(promoCode);
    if (promoCode == 'DIS30') {
      throw const ApiError(
        code: 'PROMO_USAGE_LIMIT',
        statusCode: 400,
        message: 'คุณใช้โค้ดนี้ครบจำนวนครั้งแล้ว',
      );
    }
    return const MessengerEstimate(totalFare: 49);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('a code the customer can no longer use: told why, taken off, '
      'priced without it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Repo();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        homeControllerProvider.overrideWith(_FakeHomeController.new),
        messengerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(messengerBookingControllerProvider, (_, _) {});
    final notifier = c.read(messengerBookingControllerProvider.notifier);
    await notifier.loadVehicleTypes();
    notifier
      ..setWeight(1)
      ..setPromoCode('DIS30');

    await notifier.estimate();
    var s = c.read(messengerBookingControllerProvider);
    expect(s.promoCode, '');
    expect(s.error, 'คุณใช้โค้ดนี้ครบจำนวนครั้งแล้ว');

    // The re-estimate without the code follows the debounce.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    s = c.read(messengerBookingControllerProvider);
    expect(repo.asked.last, '');
    expect(s.estimate?.totalFare, 49);
  });

  test(
    'a parcel the system cancelled for want of a driver offers a rebook',
    () {
      final o = MessengerOrder.fromJson({
        'id': 'm1',
        'status': 'CANCELLED',
        'cancel_reason': 'ไม่พบคนขับในขณะนี้',
        'cancel_reason_code': 'NO_DRIVER_AVAILABLE',
      });
      expect(o.noDriverFound, isTrue);
      expect(
        MessengerOrder.fromJson({
          'id': 'm2',
          'status': 'CANCELLED',
          'cancel_reason': 'เปลี่ยนใจ',
        }).noDriverFound,
        isFalse,
      );
    },
  );
}
