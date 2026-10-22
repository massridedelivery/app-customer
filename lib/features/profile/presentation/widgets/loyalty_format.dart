import 'package:customer_app/core/utils/app_dates.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

final _points = NumberFormat('#,##0');
final _bahtWhole = NumberFormat('#,##0');
final _bahtFraction = NumberFormat('#,##0.00');

/// Points as a whole number with thousands separators: 1,250.
String fmtPoints(num points) => _points.format(points.round());

/// Baht without decimals when whole (฿130), else two (฿12.50). No "฿".
String fmtBaht(num baht) => baht == baht.roundToDouble()
    ? _bahtWhole.format(baht)
    : _bahtFraction.format(baht);

/// A date in Thailand time, whatever the device timezone: "10 พ.ย. 2569".
String fmtThaiDate(BuildContext context, DateTime date) =>
    AppDates.of(context).date(AppDates.bangkok(date));
