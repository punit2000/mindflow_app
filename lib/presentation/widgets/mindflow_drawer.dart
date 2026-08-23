import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/route_exit.dart';
import '../screens/library/rss_feed_list_screen.dart';
import '../screens/library/wikipedia_search_screen.dart';
import '../screens/reminders/focus_mode_screen.dart';
import '../screens/reminders/pomodoro_timer_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stats/stats_screen.dart';

/// Global hamburger menu that gives quick access to every major screen from
/// anywhere in the app, so stats, settings, and tools are always one tap away.
class MindFlowDrawer extends StatelessWidget {
  const MindFlowDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    void push(Widget screen) {
      final navigator = Navigator.of(context);
      navigator.pop();
      waitForRouteExit().then((_) {
        navigator.push(MaterialPageRoute(builder: (_) => screen));
      });
    }

    return Drawer(
      backgroundColor: bgColor,
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MindFlow',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Notes · Reminders · Focus',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.show_chart_rounded,
                    label: 'Stats & Insights',
                    color: const Color(0xFFFA114F),
                    onTap: () => push(const StatsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.do_not_disturb_on_rounded,
                    label: 'Focus Mode',
                    color: const Color(0xFF34C759),
                    onTap: () => push(const FocusModeScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.timer_rounded,
                    label: 'Pomodoro Timer',
                    color: const Color(0xFFFF9500),
                    onTap: () => push(const PomodoroTimerScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.rss_feed_rounded,
                    label: 'RSS Feeds',
                    color: const Color(0xFF00C2FF),
                    onTap: () => push(const RssFeedListScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.travel_explore_rounded,
                    label: 'Read Wikipedia',
                    color: const Color(0xFF6F61FF),
                    onTap: () => push(const WikipediaSearchScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: AppColors.primary,
                    onTap: () => push(const SettingsScreen()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'MindFlow v1.5.0',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}