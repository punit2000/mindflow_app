import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/home_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/digest_provider.dart';
import '../../providers/home_layout_provider.dart';
import '../reminders/focus_mode_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final digestTime = ref.watch(digestTimeProvider);
    final digestEnabled = ref.watch(digestEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Daily Digest Section
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Daily Digest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Enable Daily Digest',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Receive a morning summary of reminders, notes, and reading activity',
                  ),
                  value: digestEnabled,
                  onChanged: (enabled) async {
                    await ref.read(digestEnabledProvider.notifier).setEnabled(enabled);
                    if (enabled) {
                      await ref.read(cancelDailyDigestProvider.future);
                      ref.invalidate(digestTimeProvider);
                      if (context.mounted) {
                        _showDigestTimePicker(context, ref, digestTime);
                      }
                    } else {
                      await ref.read(cancelDailyDigestProvider.future);
                    }
                  },
                  activeThumbColor: AppColors.primary,
                ),
                if (digestEnabled)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDigestTimePicker(context, ref, digestTime),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Summary Time',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              digestTime.when(
                                loading: () => Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                error: (_, _) => Text(
                                  '8:00 AM (default)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                data: (time) => Text(
                                  time == null
                                      ? '8:00 AM (default)'
                                      : '${time.$1.toString().padLeft(2, '0')}:${time.$2.toString().padLeft(2, '0')} ${time.$1 >= 12 ? 'PM' : 'AM'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive a daily summary of your reminders, notes, and reading activity at this time.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 40),

          // Focus Mode Section
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Focus Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final blocked = ref.watch(focusBlockedAppsProvider);
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.do_not_disturb_on_rounded, color: AppColors.primary),
                      title: const Text(
                        'Focus Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Pause notifications and block distracting apps during focus sessions',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FocusModeScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.apps_rounded, color: AppColors.primary),
                      title: const Text(
                        'Blocked apps',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        blocked.isEmpty
                            ? 'Choose apps that get locked during focus'
                            : '${blocked.length} app(s) selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => BlockedAppsScreen.open(context, ref),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),

          // Customizable Home Section
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Home Screen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Reorder & customize tabs',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(homeLayoutProvider.notifier).resetToDefault();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final layout = ref.watch(homeLayoutProvider);
                    final notifier = ref.read(homeLayoutProvider.notifier);

                    return Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: layout.visibleTabs.length,
                          onReorderItem: (oldIndex, newIndex) {
                            notifier.reorder(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final tab = layout.visibleTabs[index];
                            return ListTile(
                              key: ValueKey('visible_${tab.storageId}'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              leading: Icon(
                                _tabIcon(tab),
                                color: AppColors.primary,
                                size: 20,
                              ),
                              title: Text(tab.label),
                              subtitle: index == 0
                                  ? const Text('First position (default tab)')
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.drag_handle_rounded,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility_off_outlined, size: 20),
                                    tooltip: 'Hide tab',
                                    onPressed: () => notifier.hide(tab),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (layout.hidden.isNotEmpty) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'HIDDEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                          for (final tab in layout.hidden)
                            ListTile(
                              key: ValueKey('hidden_${tab.storageId}'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              leading: Icon(
                                _tabIcon(tab),
                                size: 20,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              title: Text(
                                tab.label,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              trailing: TextButton.icon(
                                onPressed: () => notifier.show(tab),
                                icon: const Icon(Icons.visibility_rounded, size: 18),
                                label: const Text('Show'),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _tabIcon(HomeTab tab) {
    return switch (tab) {
      HomeTab.reminders => Icons.alarm_on_rounded,
      HomeTab.notes => Icons.edit_note_rounded,
      HomeTab.library => Icons.menu_book_rounded,
    };
  }

  void _showDigestTimePicker(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<(int, int)?> digestTime,
  ) async {
    // Get current time
    var hour = 8;
    var minute = 0;

    digestTime.whenData((time) {
      if (time != null) {
        hour = time.$1;
        minute = time.$2;
      }
    });

    final timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (timePicked != null && context.mounted) {
      // Schedule the digest
      await ref.read(scheduleDailyDigestProvider((timePicked.hour, timePicked.minute)).future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily digest scheduled for ${timePicked.format(context)}',
            ),
          ),
        );
      }

      // Invalidate the digestTimeProvider to refresh
      ref.invalidate(digestTimeProvider);
    }
  }
}
