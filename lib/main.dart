import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize offline persistent storage
  final storageService = await StorageService.init();

  // 2. Initialize local notifications & timezone service
  final notificationService = NotificationService();
  await notificationService.init();

  // 3. Check if this is the first launch
  final isFirstLaunch = storageService.isFirstLaunch();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: MindFlowApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MindFlowApp extends ConsumerWidget {
  final bool isFirstLaunch;

  const MindFlowApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MindFlow Reminders & Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: isFirstLaunch ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
