import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advance_booking round-trips through the API value', () {
    expect(SupportCategory.advanceBooking.api, 'advance_booking');
    expect(
      SupportCategory.fromApi('advance_booking'),
      SupportCategory.advanceBooking,
    );
  });

  test('offered first for a ride booked ahead, nowhere else', () {
    expect(
      SupportCategory.forService(
        SupportService.ride,
        advanceBooking: true,
      ).first,
      SupportCategory.advanceBooking,
    );
    for (final s in [null, ...SupportService.values]) {
      expect(
        SupportCategory.forService(s),
        isNot(contains(SupportCategory.advanceBooking)),
        reason: '$s',
      );
    }
    // Only rides are booked ahead.
    expect(
      SupportCategory.forService(SupportService.food, advanceBooking: true),
      isNot(contains(SupportCategory.advanceBooking)),
    );
  });
}
