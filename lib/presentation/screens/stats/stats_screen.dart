import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/note.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/notes_provider.dart';
import '../../providers/reminders_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = ref.watch(notesProvider);
    final dailyStats = ref.watch(dailyStatsProvider);
    final habitStats = ref.watch(habitStatsProvider);

    final now = DateTime.now();
    final notesToday = notes
        .where((n) => _isSameDay(n.createdAt, now))
        .length;
    final notesThisWeek = notes
        .where((n) => n.createdAt.isAfter(now.subtract(const Duration(days: 7))))
        .length;

    final habitProgress = habitStats.totalHabits == 0
        ? 0.0
        : (habitStats.completedToday / habitStats.totalHabits).clamp(0.0, 1.0);

    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats & Insights'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date headline
            Text(
              DateFormat('EEEE, MMMM d').format(now),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your day at a glance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),

            // Today summary grid (big clear numbers)
            _TodaySummaryGrid(
              notesToday: notesToday,
              completedToday: dailyStats.completedToday,
              totalToday: dailyStats.totalToday,
              habitsDone: habitStats.completedToday,
              habitsTotal: habitStats.totalHabits,
            ),
            const SizedBox(height: 16),

            // Current streak banner
            _StreakBanner(
              streakDays: dailyStats.streakDays,
              bestHabitStreak: habitStats.bestStreak,
            ),
            const SizedBox(height: 24),

            // Today's completion
            Text('Today\'s Completion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _CompletionCard(
              isDark: isDark,
              title: 'Reminders',
              done: dailyStats.completedToday,
              total: dailyStats.totalToday,
              progress: dailyStats.progress,
              color: AppColors.success,
              icon: Icons.alarm_on_rounded,
            ),
            const SizedBox(height: 12),
            _CompletionCard(
              isDark: isDark,
              title: 'Habits',
              done: habitStats.completedToday,
              total: habitStats.totalHabits,
              progress: habitProgress,
              color: const Color(0xFF00C2FF),
              icon: Icons.repeat_rounded,
            ),
            const SizedBox(height: 24),

            // Notes per week
            Text('Notes Created — Last 7 Days', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '$notesThisWeek this week · $notesToday today',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: _NotesPerWeekChart(notes: notes),
            ),
            const SizedBox(height: 24),

            // Tags distribution (horizontal bars — clearer than a pie)
            Text('Top Tags', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: _TagsDistributionList(notes: notes),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TodaySummaryGrid extends StatelessWidget {
  const _TodaySummaryGrid({
    required this.notesToday,
    required this.completedToday,
    required this.totalToday,
    required this.habitsDone,
    required this.habitsTotal,
  });

  final int notesToday;
  final int completedToday;
  final int totalToday;
  final int habitsDone;
  final int habitsTotal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Widget cell({
      required IconData icon,
      required Color color,
      required String value,
      required String label,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(
          icon: Icons.edit_note_rounded,
          color: const Color(0xFFFA114F),
          value: '$notesToday',
          label: 'Notes',
        ),
        const SizedBox(width: 10),
        cell(
          icon: Icons.alarm_on_rounded,
          color: AppColors.success,
          value: totalToday == 0 ? '—' : '$completedToday/$totalToday',
          label: 'Reminders',
        ),
        const SizedBox(width: 10),
        cell(
          icon: Icons.repeat_rounded,
          color: const Color(0xFF00C2FF),
          value: habitsTotal == 0 ? '—' : '$habitsDone/$habitsTotal',
          label: 'Habits',
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streakDays, required this.bestHabitStreak});

  final int streakDays;
  final int bestHabitStreak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF9500), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day streak',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  bestHabitStreak > 0
                      ? 'Best habit streak: $bestHabitStreak day(s)'
                      : 'Keep completing reminders to grow your streak',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.isDark,
    required this.title,
    required this.done,
    required this.total,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final bool isDark;
  final String title;
  final int done;
  final int total;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                total == 0 ? 'No items today' : '${(progress * 100).round()}% done',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: total == 0 ? textSecondary : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.0 : progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              total == 0 ? '' : '$done of $total completed today',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesPerWeekChart extends StatelessWidget {
  const _NotesPerWeekChart({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final weekData = _calculateWeekData();
    final maxY = weekData.fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final chartMax = (maxY + 1).toDouble();
    final dayLabels = _dayLabels();

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    height: 12,
                    alignment: Alignment.center,
                    child: weekData[i] == 0
                        ? null
                        : Text(
                            '${weekData[i]}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                  ),
                  Container(
                    height: 120,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 18,
                      height: chartMax == 1
                          ? (weekData[i] == 0 ? 4.0 : 120.0 * (weekData[i] / chartMax))
                          : 120.0 * (weekData[i] / chartMax),
                      decoration: BoxDecoration(
                        color: i == 6
                            ? const Color(0xFFFA114F)
                            : AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<int> _calculateWeekData() {
    final now = DateTime.now();
    final data = List<int>.filled(7, 0);

    for (final note in notes) {
      final createdAt = note.createdAt;
      final daysAgo = DateTime(now.year, now.month, now.day)
          .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
          .inDays;

      if (daysAgo >= 0 && daysAgo < 7) {
        data[6 - daysAgo]++;
      }
    }

    return data;
  }

  List<String> _dayLabels() {
    final now = DateTime.now();
    final formatter = DateFormat('E');
    return List.generate(7, (i) => formatter.format(now.subtract(Duration(days: 6 - i))));
  }
}

class _TagsDistributionList extends StatelessWidget {
  const _TagsDistributionList({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final tagCounts = _calculateTagCounts();

    if (tagCounts.isEmpty) {
      final textSecondary = Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No tags yet — add tags to your notes to see them here.',
              style: TextStyle(color: textSecondary)),
        ),
      );
    }

    final entries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final display = entries.take(6).toList();
    final maxCount = display.first.value;

    return Column(
      children: [
        for (var i = 0; i < display.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _TagRow(
            tag: display[i].key,
            count: display[i].value,
            fraction: maxCount == 0 ? 0.0 : (display[i].value / maxCount),
            color: _getColorForIndex(i),
          ),
        ],
      ],
    );
  }

  Map<String, int> _calculateTagCounts() {
    final tagCounts = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    return tagCounts;
  }

  Color _getColorForIndex(int index) {
    const colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      Color(0xFF6F61FF),
      Color(0xFFFF6B9D),
    ];
    return colors[index % colors.length];
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String tag;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
