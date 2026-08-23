import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import 'storage_service.dart';

class DigestService {
  DigestService(this._flutterLocalNotificationsPlugin);

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
  }

  /// Schedule daily digest notification at specified time
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required List<Reminder> todayReminders,
    required int notesThisWeek,
    required int articlesRead,
  }) async {
    try {
      final storage = await StorageService.init();
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Calculate summary
      final reminderCount = todayReminders.length;
      final completedCount = todayReminders.where((r) => r.isCompleted).length;

      final summaryText = _buildSummary(
        reminderCount,
        completedCount,
        notesThisWeek,
        articlesRead,
      );

      // Convert to timezone-aware datetime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Cancel any existing digest notification
      await _flutterLocalNotificationsPlugin.cancel(id: 9999);

      // Schedule the recurring daily notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 9999,
        title: 'Daily Summary',
        body: summaryText,
        scheduledDate: tzScheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Digest',
            channelDescription: 'Daily summary of reminders and activity',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Save the digest time to storage
      await storage.saveDigestTime(hour, minute);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel the scheduled daily digest
  Future<void> cancel() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: 9999);
    } catch (e) {
      rethrow;
    }
  }

  /// Get the stored digest time
  Future<(int, int)?> getDigestTime() async {
    try {
      final storage = await StorageService.init();
      final hour = storage.loadDigestHour();
      final minute = storage.loadDigestMinute();
      return (hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Build the summary text for the digest
  String _buildSummary(
    int totalReminders,
    int completedReminders,
    int notesThisWeek,
    int articlesRead,
  ) {
    final remainingReminders = totalReminders - completedReminders;
    final completionRate =
        totalReminders > 0 ? (completedReminders / totalReminders * 100).toStringAsFixed(0) : '0';

    final parts = <String>[];

    if (totalReminders > 0) {
      if (completedReminders == totalReminders) {
        parts.add('✓ All reminders completed today!');
      } else {
        parts.add('Today: $remainingReminders reminders pending ($completionRate% completed)');
      }
    }

    if (notesThisWeek > 0) {
      parts.add('This week: $notesThisWeek notes created');
    }

    if (articlesRead > 0) {
      parts.add('$articlesRead articles read');
    }

    if (parts.isEmpty) {
      return 'Have a productive day! No reminders or activities scheduled.';
    }

    return parts.join('\n');
  }
}
