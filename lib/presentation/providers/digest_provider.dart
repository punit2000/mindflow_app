import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/digest_service.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';
import 'notes_provider.dart';
import 'reminders_provider.dart';

final digestServiceProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return DigestService(notificationService.flutterLocalNotificationsPlugin);
});

final digestTimeProvider = FutureProvider<(int, int)?>((ref) async {
  final digestService = ref.watch(digestServiceProvider);
  return digestService.getDigestTime();
});

final digestEnabledProvider = StateNotifierProvider<DigestEnabledNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DigestEnabledNotifier(storage);
});

class DigestEnabledNotifier extends StateNotifier<bool> {
  DigestEnabledNotifier(this._storage) : super(_storage.loadDigestEnabled());

  final StorageService _storage;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _storage.saveDigestEnabled(enabled);
  }
}

final cancelDailyDigestProvider = FutureProvider<void>((ref) async {
  final digestService = ref.watch(digestServiceProvider);
  await digestService.init();
  await digestService.cancel();
});

final scheduleDailyDigestProvider = FutureProvider.family<void, (int, int)>((ref, args) async {
  final (hour, minute) = args;
  final digestService = ref.watch(digestServiceProvider);
  await digestService.init();
  final reminders = ref.watch(remindersProvider);

  // Filter today's reminders
  final now = DateTime.now();
  final todayReminders = reminders
      .where((r) => r.scheduledTime.year == now.year && r.scheduledTime.month == now.month && r.scheduledTime.day == now.day)
      .toList();

  // Count notes this week
  final notes = ref.watch(notesProvider);
  final weekAgo = now.subtract(const Duration(days: 7));
  final notesThisWeek = notes
      .where((note) {
        try {
          return note.createdAt.isAfter(weekAgo);
        } catch (_) {
          return false;
        }
      })
      .length;

  // For now, we'll use a placeholder for articles read
  final articlesRead = 0; // TODO: Integrate with web_articles_provider

  await digestService.scheduleDaily(
    hour: hour,
    minute: minute,
    todayReminders: todayReminders,
    notesThisWeek: notesThisWeek,
    articlesRead: articlesRead,
  );
});
