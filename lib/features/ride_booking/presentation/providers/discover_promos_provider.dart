import 'package:customer_app/features/ride_booking/domain/models/ride_promo.dart';
import 'package:customer_app/features/ride_booking/domain/usecases/get_discover_promos_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoverPromosProvider = FutureProvider.autoDispose<List<RidePromo>>((ref) async {
  // Use ref.read (not ref.watch) so the future runs to completion without being
  // restarted mid-flight if rideBookingRepositoryProvider is invalidated by
  // the booking controller's loading/data state transitions.
  final useCase = ref.read(getDiscoverPromosUseCaseProvider);
  return await useCase();
});
