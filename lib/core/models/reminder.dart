import 'package:flutter/foundation.dart';
import 'priority.dart';
import 'repeat_interval.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final RepeatInterval repeatInterval;
  final PriorityLevel priority;
  final bool isCompleted;
  final bool isActive;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Habit tracking: dates on which a recurring reminder was checked off.
  final List<DateTime> completedDates;

  // Google Calendar Sync Fields
  final String? calendarEventId;
  final String? calendarId;
  final DateTime? lastSyncedAt;
  final bool isSyncedFromCalendar;

  // Device-calendar export fields (OAuth-free Android/iOS workaround).
  final String? deviceCalendarEventId;
  final String? deviceCalendarId;

  const Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.scheduledTime,
    this.repeatInterval = RepeatInterval.none,
    this.priority = PriorityLevel.medium,
    this.isCompleted = false,
    this.isActive = true,
    this.tags = const [],
    required this.createdAt,
    this.completedAt,
    this.completedDates = const [],
    this.calendarEventId,
    this.calendarId,
    this.lastSyncedAt,
    this.isSyncedFromCalendar = false,
    this.deviceCalendarEventId,
    this.deviceCalendarId,
  });

  bool get isDueToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    return scheduledTime.isBefore(DateTime.now());
  }

  bool get isCalendarSynced => calendarEventId != null && calendarEventId!.isNotEmpty;

  int get notificationId {
    return id.hashCode & 0x7fffffff;
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    RepeatInterval? repeatInterval,
    PriorityLevel? priority,
    bool? isCompleted,
    bool? isActive,
    List<String>? tags,
    DateTime? createdAt,
    ValueGetter<DateTime?>? completedAt,
    List<DateTime>? completedDates,
    String? calendarEventId,
    String? calendarId,
    DateTime? lastSyncedAt,
    bool? isSyncedFromCalendar,
    String? deviceCalendarEventId,
    String? deviceCalendarId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      completedDates: completedDates ?? this.completedDates,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarId: calendarId ?? this.calendarId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncedFromCalendar: isSyncedFromCalendar ?? this.isSyncedFromCalendar,
      deviceCalendarEventId: deviceCalendarEventId ?? this.deviceCalendarEventId,
      deviceCalendarId: deviceCalendarId ?? this.deviceCalendarId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'repeatInterval': repeatInterval.name,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'isActive': isActive,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'calendarEventId': calendarEventId,
      'calendarId': calendarId,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'isSyncedFromCalendar': isSyncedFromCalendar,
      'deviceCalendarEventId': deviceCalendarEventId,
      'deviceCalendarId': deviceCalendarId,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduledTime: DateTime.tryParse(json['scheduledTime'] as String? ?? '') ?? DateTime.now(),
      repeatInterval: RepeatInterval.fromString(json['repeatInterval'] as String?),
      priority: PriorityLevel.fromString(json['priority'] as String?),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => DateTime.tryParse(e.toString()))
              .whereType<DateTime>()
              .toList() ??
          const [],
      calendarEventId: json['calendarEventId'] as String?,
      calendarId: json['calendarId'] as String?,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      isSyncedFromCalendar: json['isSyncedFromCalendar'] as bool? ?? false,
      deviceCalendarEventId: json['deviceCalendarEventId'] as String?,
      deviceCalendarId: json['deviceCalendarId'] as String?,
    );
  }
}
