import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../screens/home/global_search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stats/stats_screen.dart';

class GlobalSearchAction extends StatelessWidget {
  const GlobalSearchAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search_rounded),
      tooltip: 'Search MindFlow',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
      ),
    );
  }
}

class ThemeToggleAction extends ConsumerWidget {
  const ThemeToggleAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        themeMode == ThemeMode.dark
            ? Icons.light_mode_rounded
            : Icons.dark_mode_rounded,
        color: isDark ? const Color(0xFFFBBF24) : AppColors.primary,
      ),
      tooltip: themeMode == ThemeMode.dark
          ? 'Switch to Light Theme'
          : 'Switch to Dark Theme',
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
    );
  }
}

class StatsAction extends StatelessWidget {
  const StatsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.show_chart_rounded),
      tooltip: 'View Stats',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatsScreen()),
      ),
    );
  }
}

class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_rounded),
      tooltip: 'Settings',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}
