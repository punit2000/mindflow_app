import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/reminder.dart';
import '../../../core/services/habit_tracker.dart';
import '../../../core/theme/app_colors.dart';

/// Shows a calendar month view of completed dates for a recurring reminder
/// (habit), along with current/best streak and a completion log.
class HabitHistoryScreen extends ConsumerStatefulWidget {
  const HabitHistoryScreen({super.key, required this.reminder});

  final Reminder reminder;

  @override
  ConsumerState<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends ConsumerState<HabitHistoryScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  List<DateTime> get _completedDays {
    final days = widget.reminder.completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return days;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminder = widget.reminder;
    final currentStreak = HabitTracker.currentStreak(reminder.completedDates);
    final bestStreak = HabitTracker.bestStreak(reminder.completedDates);
    final completedCount = _completedDays.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(reminder.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Stat chips
          Row(
            children: [
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: 'Current streak',
                value: '$currentStreak days',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: 'Best streak',
                value: '$bestStreak days',
                color: AppColors.success,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                value: '$completedCount days',
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Month calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_visibleMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Column(
              children: [
                // Weekday headers
                Row(
                  children: [
                    for (final day in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _MonthGrid(
                  month: _visibleMonth,
                  completedDays: _completedDays,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Completion log
          Text('Completion Log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_completedDays.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No completions recorded yet. Check off this habit to see its history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            for (final day in _completedDays.take(30))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                title: Text(
                  DateFormat('EEEE, MMM d, yyyy').format(day),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.completedDays});

  final DateTime month;
  final List<DateTime> completedDays;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sunday-first week grid

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const Expanded(child: SizedBox()));
    }

    final completedSet = completedDays
        .where((d) => d.year == month.year && d.month == month.month)
        .map((d) => d.day)
        .toSet();

    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = month.year == today.year && month.month == today.month && day == today.day;
      final isCompleted = completedSet.contains(day);

      cells.add(
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday || isCompleted ? FontWeight.w800 : FontWeight.w500,
                    color: isCompleted
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(children: cells);
  }
}