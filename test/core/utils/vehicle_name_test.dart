import 'package:customer_app/core/utils/vehicle_name_th.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vehicleName', () {
    test('Thai mode keeps the Thai names', () {
      expect(vehicleName('Comfort Car'), 'รถ Comfort');
      expect(vehicleName('Economy Car', languageCode: 'th'), 'รถ Eco car');
      expect(vehicleName('Van', languageCode: 'th'), 'รถตู้');
    });

    test('Thai motorcycle name uses the corrected spelling', () {
      expect(vehicleName('Motorcycle (Ride Only)'), 'มอเตอร์ไซค์ (ผู้โดยสาร)');
      expect(
        vehicleName('Moto X', vehicleTypeName: 'motorcycle_ride'),
        'มอเตอร์ไซค์ (ผู้โดยสาร)',
      );
    });

    test('English mode shows clean English names', () {
      expect(vehicleName('Comfort Car', languageCode: 'en'), 'Comfort');
      expect(vehicleName('Economy Car', languageCode: 'en'), 'Eco car');
      expect(
        vehicleName('Motorcycle (Ride Only)', languageCode: 'en'),
        'Motorcycle',
      );
      expect(vehicleName('Tuk-Tuk', languageCode: 'en'), 'Tuk-Tuk');
    });

    test('English mode falls back to the API display name', () {
      expect(
        vehicleName(
          'Luxury Sedan',
          vehicleTypeName: 'car_luxury',
          languageCode: 'en',
        ),
        'Luxury Sedan',
      );
    });
  });
}
