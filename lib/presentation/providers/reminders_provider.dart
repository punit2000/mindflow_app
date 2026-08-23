import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/priority.dart';
import '../../core/models/reminder.dart';
import '../../core/models/repeat_interval.dart';
import '../../core/services/habit_tracker.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

enum ReminderFilterTab {
  today,
  upcoming,
  recurring,
  completed;

  String get title {
    switch (this) {
      case ReminderFilterTab.today:
        return 'Today';
      case ReminderFilterTab.upcoming:
        return 'Upcoming';
      case ReminderFilterTab.recurring:
        return 'Recurring';
      case ReminderFilterTab.completed:
        return 'Completed';
    }
  }
}

// Active Tab in Reminders Screen
final reminderFilterTabProvider = StateProvider<ReminderFilterTab>((ref) => ReminderFilterTab.today);

// Search Query for Reminders
final remindersSearchQueryProvider = StateProvider<String>((ref) => '');

// Priority Filter (null = All)
final selectedPriorityFilterProvider = StateProvider<PriorityLevel?>((ref) => null);

// Reminders StateNotifier Provider
final remindersProvider = StateNotifierProvider<RemindersNotifier, List<Reminder>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return RemindersNotifier(storage, notificationService);
});

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  final StorageService _storage;
  final NotificationService _notificationService;

  RemindersNotifier(this._storage, this._notificationService) : super([]) {
    _load();
  }

  void _load() {
    state = _storage.loadReminders();
    // Ensure all active reminders are scheduled
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    for (final reminder in state) {
      if (reminder.isActive && !reminder.isCompleted) {
        await _notificationService.scheduleReminder(reminder);
      }
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    final updatedState = [reminder, ...state];
    final didSave = await _storage.saveReminders(updatedState);
    if (!didSave) {
      throw StateError('Could not save the reminder on this device.');
    }
    state = updatedState;
    await _notificationService.scheduleReminder(reminder);
  }

  Future<void> updateReminder(Reminder updatedReminder) async {
    // Cancel previous notification and reschedule
    await _notificationService.cancelReminder(updatedReminder.notificationId);

    final updatedState = [
      for (final reminder in state)
        if (reminder.id == updatedReminder.id) updatedReminder else reminder
    ];
    final didSave = await _storage.saveReminders(updatedState);
    if (!didSave) {
      throw StateError('Could not save the reminder changes on this device.');
    }
    state = updatedState;

    if (updatedReminder.isActive && !updatedReminder.isCompleted) {
      await _notificationService.scheduleReminder(updatedReminder);
    }
  }

  Future<void> toggleComplete(String id) async {
    final target = state.firstWhere((r) => r.id == id);
    final isNowCompleted = !target.isCompleted;

    if (isNowCompleted) {
      await _notificationService.cancelReminder(target.notificationId);

      // If it is a recurring reminder (habit), record today's completion date
      // and advance the schedule to the next occurrence.
      if (target.repeatInterval != RepeatInterval.none) {
        final nextTime = target.repeatInterval.calculateNextOccurrence(
          target.scheduledTime.add(const Duration(days: 1)),
        );
        final recurringNext = target.copyWith(
          scheduledTime: nextTime,
          isCompleted: false,
          completedAt: () => DateTime.now(),
          completedDates: [...target.completedDates, DateTime.now()],
        );
        await updateReminder(recurringNext);
        return;
      }
    }

    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(
            isCompleted: isNowCompleted,
            completedAt: isNowCompleted ? () => DateTime.now() : () => null,
          )
        else
          reminder
    ];
    await _storage.saveReminders(state);

    if (!isNowCompleted && target.isActive) {
      await _notificationService.scheduleReminder(target.copyWith(isCompleted: false));
    }
  }

  Future<void> snoozeReminder(String id, Duration duration) async {
    final target = state.firstWhere((r) => r.id == id);
    final newTime = DateTime.now().add(duration);

    final snoozed = target.copyWith(
      scheduledTime: newTime,
      isCompleted: false,
    );

    await updateReminder(snoozed);
  }

  Future<void> deleteReminder(String id) async {
    final target = state.firstWhere((r) => r.id == id, orElse: () => state.first);
    await _notificationService.cancelReminder(target.notificationId);

    state = state.where((r) => r.id != id).toList();
    await _storage.saveReminders(state);
  }

  Future<void> setRemindersFromSync(List<Reminder> newReminders) async {
    state = newReminders;
    await _storage.saveReminders(state);
    await _syncNotifications();
  }
}

// Filtered Reminders Provider
final filteredRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final activeTab = ref.watch(reminderFilterTabProvider);
  final searchQuery = ref.watch(remindersSearchQueryProvider).trim().toLowerCase();
  final priorityFilter = ref.watch(selectedPriorityFilterProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  var list = reminders;

  // 1. Tab Filter
  switch (activeTab) {
    case ReminderFilterTab.today:
      list = list.where((r) {
        if (r.isCompleted) return false;
        final isToday = r.scheduledTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            r.scheduledTime.isBefore(todayEnd);
        final isPastDue = r.scheduledTime.isBefore(now);
        return isToday || isPastDue;
      }).toList();
      break;

    case ReminderFilterTab.upcoming:
      list = list.where((r) {
        if (r.isCompleted) return false;
        return r.scheduledTime.isAfter(todayEnd);
      }).toList();
      break;

    case ReminderFilterTab.recurring:
      list = list.where((r) => r.repeatInterval != RepeatInterval.none && !r.isCompleted).toList();
      break;

    case ReminderFilterTab.completed:
      list = list.where((r) => r.isCompleted).toList();
      break;
  }

  // 2. Priority Filter
  if (priorityFilter != null) {
    list = list.where((r) => r.priority == priorityFilter).toList();
  }

  // 3. Search Query
  if (searchQuery.isNotEmpty) {
    list = list.where((r) {
      final titleMatch = r.title.toLowerCase().contains(searchQuery);
      final descMatch = r.description.toLowerCase().contains(searchQuery);
      final tagMatch = r.tags.any((t) => t.toLowerCase().contains(searchQuery));
      return titleMatch || descMatch || tagMatch;
    }).toList();
  }

  // Sort by scheduledTime ascending (soonest first)
  list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return list;
});

// Daily Completion Stats Provider
class DailyStats {
  final int totalToday;
  final int completedToday;
  final double progress;
  final int streakDays;

  const DailyStats({
    required this.totalToday,
    required this.completedToday,
    required this.progress,
    required this.streakDays,
  });
}

final dailyStatsProvider = Provider<DailyStats>((ref) {
  final reminders = ref.watch(remindersProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final todayTasks = reminders.where((r) {
    final dueToday = r.scheduledTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        r.scheduledTime.isBefore(todayEnd);
    final completedToday = r.completedAt != null &&
        r.completedAt!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        r.completedAt!.isBefore(todayEnd);
    return dueToday || completedToday;
  }).toList();

  final total = todayTasks.length;
  final completed = todayTasks.where((r) => r.isCompleted).length;
  final progress = total == 0 ? 1.0 : (completed / total);

  // Streak is based on the overall completion history across all habits and
  // one-off reminders (their completedAt dates).
  final allCompletionDates = <DateTime>[
    for (final r in reminders) ...r.completedDates,
    for (final r in reminders)
      if (r.completedAt != null) r.completedAt!,
  ];

  return DailyStats(
    totalToday: total,
    completedToday: completed,
    progress: progress.clamp(0.0, 1.0),
    streakDays: HabitTracker.currentStreak(allCompletionDates),
  );
});

// Habit-specific stats: habits are recurring reminders with tracked dates.
class HabitStats {
  final int totalHabits;
  final int completedToday;
  final int bestStreak;

  const HabitStats({
    required this.totalHabits,
    required this.completedToday,
    required this.bestStreak,
  });
}

final habitStatsProvider = Provider<HabitStats>((ref) {
  final reminders = ref.watch(remindersProvider);
  final habits = reminders.where((r) => r.repeatInterval != RepeatInterval.none).toList();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var completedToday = 0;
  var bestStreak = 0;
  for (final habit in habits) {
    if (HabitTracker.completedOn(habit, today)) completedToday++;
    final streak = HabitTracker.bestStreak(habit.completedDates);
    if (streak > bestStreak) bestStreak = streak;
  }

  return HabitStats(
    totalHabits: habits.length,
    completedToday: completedToday,
    bestStreak: bestStreak,
  );
});
