import 'package:customer_app/core/utils/thai_date_formatter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_order_item.freezed.dart';
part 'active_order_item.g.dart';

/// Lean summary item from `GET /api/customer/active` (SCRUM-45).
/// A cross-vertical index (ride + food + messenger) meant for routing to the
/// per-vertical detail endpoint via [type] + [id] — not full detail.
@freezed
abstract class ActiveOrderItem with _$ActiveOrderItem {
  const ActiveOrderItem._();

  const factory ActiveOrderItem({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'type') @Default('') String type,
    @JsonKey(name: 'status') @Default('') String status,
    @JsonKey(name: 'driver_id') @Default('') String driverId,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
  }) = _ActiveOrderItem;

  factory ActiveOrderItem.fromJson(Map<String, dynamic> json) =>
      _$ActiveOrderItemFromJson(json);

  bool get isRide => type.toUpperCase() == 'RIDE';
  bool get isFood => type.toUpperCase() == 'FOOD';
  bool get isMessenger => type.toUpperCase() == 'MESSENGER';
  bool get hasDriver => driverId.isNotEmpty;

  String get formattedCreatedAt => ThaiDateFormatter.dateTime(createdAt);
}
