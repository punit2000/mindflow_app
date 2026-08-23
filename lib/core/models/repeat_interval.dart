enum RepeatInterval {
  none,
  hourly,
  daily,
  weekdays,
  weekly;

  String get label {
    switch (this) {
      case RepeatInterval.none:
        return 'Once';
      case RepeatInterval.hourly:
        return 'Hourly';
      case RepeatInterval.daily:
        return 'Daily';
      case RepeatInterval.weekdays:
        return 'Weekdays (Mon-Fri)';
      case RepeatInterval.weekly:
        return 'Weekly';
    }
  }

  static RepeatInterval fromString(String? val) {
    if (val == null) return RepeatInterval.none;
    return RepeatInterval.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RepeatInterval.none,
    );
  }

  /// Calculates the next occurrence time based on this repeat interval
  DateTime calculateNextOccurrence(DateTime currentScheduled) {
    final now = DateTime.now();
    DateTime next = currentScheduled;

    switch (this) {
      case RepeatInterval.none:
        return currentScheduled;
      case RepeatInterval.hourly:
        while (next.isBefore(now)) {
          next = next.add(const Duration(hours: 1));
        }
        return next;
      case RepeatInterval.daily:
        while (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RepeatInterval.weekdays:
        while (next.isBefore(now) || next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RepeatInterval.weekly:
        while (next.isBefore(now)) {
          next = next.add(const Duration(days: 7));
        }
        return next;
    }
  }
}
