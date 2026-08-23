import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';

// Storage Service Provider (Overridden in main.dart after init)
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized');
});

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Active Tab Index Provider (0 = Reminders, 1 = Notes)
final currentTabProvider = StateProvider<int>((ref) => 0);

// Apps selected to be blocked during focus mode
final focusBlockedAppsProvider = StateProvider<List<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.loadFocusBlockedPackages();
});

// Global Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_loadInitial(_storage));

  static ThemeMode _loadInitial(StorageService storage) {
    final saved = storage.loadThemeMode();
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _storage.saveThemeMode(mode.name);
  }
}
