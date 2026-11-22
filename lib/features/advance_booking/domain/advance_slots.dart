/// The pickup times a ride may be booked ahead for, in slot steps.
///
/// All instants are UTC. Days, hours and minutes are Bangkok wall clock
/// (UTC+7, no daylight saving): the time picker shows Bangkok time whatever
/// the phone's zone. Bangkok is a whole number of hours off UTC, so rounding
/// to a slot on the UTC clock lands on the same Bangkok slot.
class AdvanceSlots {
  AdvanceSlots({
    required DateTime now,
    required int minLeadMinutes,
    required int maxDays,
    required int slotMinutes,
  }) : slotMinutes = slotMinutes <= 0 ? 5 : slotMinutes,
       earliest = earliestSlot(now, minLeadMinutes, slotMinutes),
       latest = _floorToSlot(
         now.toUtc().add(Duration(days: maxDays < 0 ? 0 : maxDays)),
         slotMinutes <= 0 ? 5 : slotMinutes,
       );

  static const bangkokOffset = Duration(hours: 7);

  final int slotMinutes;

  /// The first bookable slot: now + lead, rounded up to the slot.
  final DateTime earliest;

  /// The last bookable slot: now + max days, rounded down to the slot.
  final DateTime latest;

  /// now + [leadMinutes], rounded up to [slotMinutes] (UTC).
  static DateTime earliestSlot(DateTime now, int leadMinutes, int slotMinutes) {
    final slot = slotMinutes <= 0 ? 5 : slotMinutes;
    final t = now.toUtc().add(
      Duration(minutes: leadMinutes < 0 ? 0 : leadMinutes),
    );
    final floor = _floorToSlot(t, slot);
    return floor == t ? t : floor.add(Duration(minutes: slot));
  }

  static DateTime _floorToSlot(DateTime t, int slot) {
    final ms = t.toUtc().millisecondsSinceEpoch;
    final step = slot * 60 * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms - ms % step, isUtc: true);
  }

  /// The Bangkok wall-clock reading of [utc] (a UTC-flagged DateTime whose
  /// fields are Bangkok's).
  static DateTime toBangkok(DateTime utc) => utc.toUtc().add(bangkokOffset);

  /// The instant of a Bangkok wall-clock reading.
  static DateTime fromBangkok(DateTime wall) => DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
  ).subtract(bangkokOffset);

  bool isBookable(DateTime utc) =>
      !utc.isBefore(earliest) && !utc.isAfter(latest);

  /// The Bangkok days a slot falls on, first to last (midnight, wall clock).
  List<DateTime> get days {
    final first = _day(toBangkok(earliest));
    final last = _day(toBangkok(latest));
    final out = <DateTime>[];
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }

  static DateTime _day(DateTime wall) =>
      DateTime.utc(wall.year, wall.month, wall.day);

  /// The minutes a slot may start at within an hour: 0, slot, 2·slot, ….
  List<int> get minutes => [for (var m = 0; m < 60; m += slotMinutes) m];

  /// Whether any slot of [hour] on Bangkok [day] is bookable.
  bool hourHasSlot(DateTime day, int hour) =>
      minutes.any((m) => isBookable(at(day, hour, m)));

  /// The instant of Bangkok [day] at [hour]:[minute].
  DateTime at(DateTime day, int hour, int minute) =>
      fromBangkok(DateTime.utc(day.year, day.month, day.day, hour, minute));

  /// [utc] moved into the bookable range, on a slot.
  DateTime clamp(DateTime utc) {
    var t = _floorToSlot(utc, slotMinutes);
    if (t.isBefore(earliest)) t = earliest;
    if (t.isAfter(latest)) t = latest;
    return t;
  }

  /// The earliest slot for a vehicle type with its own lead time.
  DateTime earliestFor(DateTime now, int vehicleLeadMinutes) =>
      earliestSlot(now, vehicleLeadMinutes, slotMinutes);
}
