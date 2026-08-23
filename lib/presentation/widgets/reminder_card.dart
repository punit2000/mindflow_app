import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/reminder.dart';
import '../../core/models/repeat_interval.dart';
import '../../core/services/habit_tracker.dart';
import '../../core/theme/app_colors.dart';
import '../providers/reminders_provider.dart';
import '../screens/reminders/habit_history_screen.dart';
import 'priority_badge.dart';

class ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final VoidCallback? onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('h:mm a').format(dt);

    if (itemDate == today) {
      return 'Today at $timeStr';
    } else if (itemDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${DateFormat('MMM d').format(dt)} at $timeStr';
    }
  }

  void _showSnoozeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Snooze Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                  title: const Text('+10 Minutes'),
                  onTap: () {
                    ref
                        .read(remindersProvider.notifier)
                        .snoozeReminder(reminder.id, const Duration(minutes: 10));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.primary),
                  title: const Text('+1 Hour'),
                  onTap: () {
                    ref
                        .read(remindersProvider.notifier)
                        .snoozeReminder(reminder.id, const Duration(hours: 1));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.primary),
                  title: const Text('Tomorrow Morning (9:00 AM)'),
                  onTap: () {
                    final now = DateTime.now();
                    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 9, 0);
                    final diff = tomorrowMorning.difference(now);
                    ref.read(remindersProvider.notifier).snoozeReminder(reminder.id, diff);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = reminder.isOverdue;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ref.read(remindersProvider.notifier).toggleComplete(reminder.id);
          return false; // Don't remove the widget, state update handles animation
        } else {
          ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
          return true;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOverdue
                ? AppColors.danger.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: isOverdue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Checkbox
                  GestureDetector(
                    onTap: () {
                      ref.read(remindersProvider.notifier).toggleComplete(reminder.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reminder.isCompleted
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: reminder.isCompleted
                              ? AppColors.success
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          width: 2,
                        ),
                      ),
                      child: reminder.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),

                  // Content Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: reminder.isCompleted
                                ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Badges & Time Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Time Indicator
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: isOverdue ? AppColors.danger : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(reminder.scheduledTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue ? AppColors.danger : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),

                            // Overdue badge
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Overdue',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            // Recurrence Pill
                            if (reminder.repeatInterval != RepeatInterval.none)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.repeat_rounded, size: 11, color: AppColors.secondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      reminder.repeatInterval.label,
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Habit Streak Badge
                            if (reminder.repeatInterval != RepeatInterval.none &&
                                reminder.completedDates.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 11,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${HabitTracker.currentStreak(reminder.completedDates)}d',
                                      style: const TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Priority Badge
                            PriorityBadge(priority: reminder.priority),

                            // Google Calendar Synced Badge
                            if (reminder.isCalendarSynced || reminder.isSyncedFromCalendar)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_available_rounded, size: 11, color: AppColors.info),
                                    SizedBox(width: 3),
                                    Text(
                                      'Google Cal',
                                      style: TextStyle(
                                        color: AppColors.info,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Tags
                            for (final tag in reminder.tags)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Snooze Quick Button
                  if (!reminder.isCompleted)
                    IconButton(
                      icon: const Icon(Icons.snooze_rounded, size: 18),
                      tooltip: 'Snooze',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      onPressed: () => _showSnoozeDialog(context, ref),
                    ),
                  if (reminder.repeatInterval != RepeatInterval.none)
                    IconButton(
                      icon: const Icon(Icons.calendar_view_month_rounded, size: 18),
                      tooltip: 'Habit history',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitHistoryScreen(reminder: reminder),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
