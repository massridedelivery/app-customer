import 'package:customer_app/features/trips/domain/models/history_order.dart';

abstract interface class ITripsRepository {
  Future<HistoryResponse> getHistoryOrders({
    HistoryType? type,
    HistoryStatus? status,
    required int page,
    required int limit,
  });

  Future<HistoryFoodDetails> getFoodOrderDetail(String id);
  Future<HistoryRideDetails> getRideOrderDetail(String id);
}
