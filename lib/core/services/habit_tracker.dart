import '../models/reminder.dart';

/// Habit tracking helpers: current streak calculation from completion dates.
class HabitTracker {
  /// Computes the current streak (consecutive days ending today or yesterday)
  /// from a list of completion [DateTime]s.
  static int currentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final days = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;
    // Allow the streak to start from today or yesterday, so a habit checked
    // off yesterday still counts until today's instance is due.
    final DateTime? startDay = days.contains(today)
        ? today
        : days.contains(yesterday)
            ? yesterday
            : null;
    if (startDay == null) return 0;

    var cursor = startDay;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest streak ever recorded for the given completion dates.
  static int bestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final days = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    int best = 0;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
      } else {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  /// True when [reminder] is a habit (repeats) and was completed on [date].
  static bool completedOn(Reminder reminder, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return reminder.completedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }
}