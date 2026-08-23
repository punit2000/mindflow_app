import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide RepeatInterval;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local_notifications show RepeatInterval;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/priority.dart';
import '../models/reminder.dart';
import '../models/repeat_interval.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _canScheduleExactAlarms = false;

  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _notificationsPlugin;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));

      // 2. Android Initialization Settings with App Icon
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/app_icon');

      // 3. iOS Initialization Settings with notification action categories
      final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'reminder_actions',
            actions: [
              DarwinNotificationAction.plain('mark_done', 'Mark Done'),
              DarwinNotificationAction.plain('snooze_10', 'Snooze 10m'),
            ],
            options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
          ),
        ],
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android Notification Channels
      await _createNotificationChannels();
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      _canScheduleExactAlarms =
          await androidImplementation?.canScheduleExactNotifications() ?? false;

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Urgent Channel
      const AndroidNotificationChannel highPriorityChannel = AndroidNotificationChannel(
        'high_priority_reminders',
        'Urgent Reminders',
        description: 'Urgent alarms and critical reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Standard Channel
      const AndroidNotificationChannel standardChannel = AndroidNotificationChannel(
        'daily_reminders',
        'Daily Reminders',
        description: 'Scheduled daily tasks and notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(highPriorityChannel);
      await androidImplementation.createNotificationChannel(standardChannel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: payload = ${response.payload}');
    if (response.actionId != null && response.payload != null) {
      unawaited(_applyNotificationAction(response.actionId!, response.payload!));
    }
  }

  Future<void> _applyNotificationAction(String actionId, String reminderId) async {
    final storage = await StorageService.init();
    final reminders = storage.loadReminders();
    final index = reminders.indexWhere((reminder) => reminder.id == reminderId);
    if (index < 0) return;

    final current = reminders[index];
    Reminder updated = current;
    if (actionId == 'mark_done') {
      updated = current.copyWith(isCompleted: true, completedAt: () => DateTime.now());
      await cancelReminder(current.notificationId);
    } else if (actionId == 'snooze_10') {
      updated = current.copyWith(
        scheduledTime: DateTime.now().add(const Duration(minutes: 10)),
        isCompleted: false,
      );
      await cancelReminder(current.notificationId);
      await scheduleReminder(updated);
    } else {
      return;
    }
    reminders[index] = updated;
    await storage.saveReminders(reminders);
  }

  Future<bool> _isFocusModeActive() async {
    try {
      final storage = await StorageService.init();
      final focusUntil = storage.loadFocusModeUntil();
      return focusUntil != null && focusUntil.isAfter(DateTime.now());
    } catch (e) {
      debugPrint('Error checking focus mode: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    bool granted = true;

    // Android 13+ (API 33+) permission request
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? androidGranted =
          await androidImplementation.requestNotificationsPermission();
      granted = androidGranted ?? false;
      if (granted) {
        await androidImplementation.requestExactAlarmsPermission();
        _canScheduleExactAlarms =
            await androidImplementation.canScheduleExactNotifications() ?? false;
      }
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final bool? iosGranted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (iosGranted ?? false);
    }

    return granted;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isInitialized || !reminder.isActive || reminder.isCompleted) return;

    // Check if focus mode is active - skip sending notifications during focus
    if (await _isFocusModeActive()) {
      debugPrint('Focus mode active. Suppressing notification for: ${reminder.title}');
      return;
    }

    try {
      final scheduledDate = reminder.scheduledTime;
      final now = DateTime.now();

      // If one-time reminder is in the past, do not schedule
      if (reminder.repeatInterval == RepeatInterval.none && scheduledDate.isBefore(now)) {
        return;
      }

      final channelId = reminder.priority == PriorityLevel.high
          ? 'high_priority_reminders'
          : 'daily_reminders';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        reminder.priority == PriorityLevel.high ? 'Urgent Reminders' : 'Daily Reminders',
        channelDescription: 'Scheduled reminders & alarms',
        icon: '@drawable/app_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_icon'),
        color: const Color(0xFF5F7F72),
        importance: reminder.priority == PriorityLevel.high ? Importance.max : Importance.high,
        priority: reminder.priority == PriorityLevel.high ? Priority.max : Priority.high,
        actions: const [
          AndroidNotificationAction('mark_done', 'Mark Done'),
          AndroidNotificationAction('snooze_10', 'Snooze 10m'),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'reminder_actions',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final scheduleMode = _canScheduleExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      if (reminder.repeatInterval == RepeatInterval.hourly) {
        await _notificationsPlugin.periodicallyShow(
          id: reminder.notificationId,
          title: '⏰ ${reminder.title}',
          body: reminder.description.isNotEmpty ? reminder.description : 'Hourly Reminder',
          repeatInterval: local_notifications.RepeatInterval.hourly,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: reminder.id,
        );
      } else if (reminder.repeatInterval == RepeatInterval.daily) {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: '⏰ ${reminder.title}',
          body: reminder.description.isNotEmpty ? reminder.description : 'Daily Reminder',
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: reminder.id,
        );
      } else if (reminder.repeatInterval == RepeatInterval.weekly) {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: '⏰ ${reminder.title}',
          body: reminder.description.isNotEmpty ? reminder.description : 'Weekly Reminder',
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: reminder.id,
        );
      } else {
        // One-time or custom occurrence
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: '⏰ ${reminder.title}',
          body: reminder.description.isNotEmpty ? reminder.description : 'Reminder Alert',
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: reminder.id,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Sends a quick test notification to demonstrate instant alert capability
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminders',
        'Daily Reminders',
        icon: '@drawable/app_icon',
        largeIcon: DrawableResourceAndroidBitmap('@drawable/app_icon'),
        color: Color(0xFF5F7F72),
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: 999999,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Test notification error: $e');
    }
  }
}
