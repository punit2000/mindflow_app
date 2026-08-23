import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/priority.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/calendar_sync_provider.dart';
import '../../widgets/app_header_actions.dart';
import '../../widgets/reminder_card.dart';
import '../../widgets/streak_header_card.dart';
import '../settings/calendar_sync_dialog.dart';
import 'add_edit_reminder_sheet.dart';
import 'focus_mode_screen.dart';

class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTab = ref.watch(reminderFilterTabProvider);
    final reminders = ref.watch(filteredRemindersProvider);
    final selectedPriority = ref.watch(selectedPriorityFilterProvider);
    final searchQuery = ref.watch(remindersSearchQueryProvider);
    final syncState = ref.watch(calendarSyncProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Header
          SliverAppBar(
            floating: true,
            pinned: false,
            leading: _MenuButton(onPressed: onMenuPressed),
            title: const Row(
              children: [
                Icon(Icons.alarm_on_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Daily Reminders',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            actions: [
              const GlobalSearchAction(),
              IconButton(
                icon: const Icon(Icons.do_not_disturb_on_rounded),
                tooltip: 'Focus Mode',
                onPressed: () => FocusModeScreen.show(context),
              ),
              IconButton(
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.sync_rounded),
                tooltip: 'Sync with Google Calendar',
                onPressed: () => CalendarSyncDialog.show(context),
              ),
              const ThemeToggleAction(),
              const SizedBox(width: 4),
            ],
          ),

          // Streak and Daily Progress Header Card
          const SliverToBoxAdapter(
            child: StreakHeaderCard(),
          ),

          // Segmented Filter Tabs (Today, Upcoming, Recurring, Completed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tab in ReminderFilterTab.values) ...[
                      ChoiceChip(
                        label: Text(tab.title),
                        selected: activeTab == tab,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(reminderFilterTabProvider.notifier).state = tab;
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: activeTab == tab
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          fontWeight: activeTab == tab ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Search & Priority Filter row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        ref.read(remindersSearchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search reminders...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority Filter Menu
                  PopupMenuButton<PriorityLevel?>(
                    initialValue: selectedPriority,
                    tooltip: 'Filter by Priority',
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedPriority != null
                            ? selectedPriority.color.withValues(alpha: 0.15)
                            : (isDark ? AppColors.darkInput : AppColors.lightInput),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedPriority != null
                              ? selectedPriority.color
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: selectedPriority != null
                            ? selectedPriority.color
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    onSelected: (p) {
                      ref.read(selectedPriorityFilterProvider.notifier).state = p;
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Priorities'),
                      ),
                      for (final p in PriorityLevel.values)
                        PopupMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Icon(p.icon, size: 16, color: p.color),
                              const SizedBox(width: 8),
                              Text(p.label),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Clear, useful context for the selected view.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Icon(
                    activeTab == ReminderFilterTab.upcoming
                        ? Icons.event_available_rounded
                        : Icons.format_list_bulleted_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${reminders.length} ${activeTab.title.toLowerCase()} ${reminders.length == 1 ? 'reminder' : 'reminders'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Text(
                      'Search active',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    )
                  else if (selectedPriority != null)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(selectedPriorityFilterProvider.notifier).state = null;
                      },
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Clear priority'),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Reminders List or Empty State
          if (reminders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 54,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          activeTab == ReminderFilterTab.completed
                              ? 'No completed tasks yet'
                              : 'All caught up!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeTab == ReminderFilterTab.today
                              ? 'No pending reminders for today. Tap + to set one!'
                              : 'No reminders found for this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (activeTab != ReminderFilterTab.completed)
                          ElevatedButton.icon(
                            onPressed: () => AddEditReminderSheet.show(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final reminder = reminders[index];
                  return ReminderCard(
                    reminder: reminder,
                    onTap: () => AddEditReminderSheet.show(context, reminder: reminder),
                  );
                },
                childCount: reminders.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: onPressed,
    );
  }
}
