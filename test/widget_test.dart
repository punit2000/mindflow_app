import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_notes_reminders/core/models/note.dart';
import 'package:flow_notes_reminders/core/models/priority.dart';
import 'package:flow_notes_reminders/core/models/reminder.dart';
import 'package:flow_notes_reminders/core/models/repeat_interval.dart';
import 'package:flow_notes_reminders/core/services/storage_service.dart';
import 'package:flow_notes_reminders/presentation/providers/app_providers.dart';
import 'package:flow_notes_reminders/main.dart';

void main() {
  group('Note Model & Checklist Tests', () {
    test('Note serialization and copyWith works correctly', () {
      final now = DateTime.now();
      final note = Note(
        id: 'test_1',
        title: 'Project Ideas',
        content: 'Build an awesome Flutter app',
        colorIndex: 2,
        tags: const ['Work', 'Tech'],
        isPinned: true,
        isChecklist: true,
        checklistItems: const [
          ChecklistItem(id: 'c1', text: 'Design UI', isChecked: true),
          ChecklistItem(id: 'c2', text: 'Write Tests', isChecked: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.id, 'test_1');
      expect(restored.title, 'Project Ideas');
      expect(restored.isPinned, isTrue);
      expect(restored.isChecklist, isTrue);
      expect(restored.checklistItems.length, 2);
      expect(restored.checklistItems[0].isChecked, isTrue);
      expect(restored.checklistItems[1].isChecked, isFalse);

      final toggled = restored.copyWith(
        checklistItems: [
          restored.checklistItems[0],
          restored.checklistItems[1].copyWith(isChecked: true),
        ],
      );
      expect(toggled.checklistItems[1].isChecked, isTrue);
    });
  });

  group('Reminder Model & Scheduling Tests', () {
    test('Reminder serialization and status calculations', () {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(hours: 2));

      final reminder = Reminder(
        id: 'rem_1',
        title: 'Daily Meeting',
        description: 'Standup call',
        scheduledTime: futureTime,
        repeatInterval: RepeatInterval.daily,
        priority: PriorityLevel.high,
        tags: const ['Meeting'],
        createdAt: now,
      );

      final json = reminder.toJson();
      final restored = Reminder.fromJson(json);

      expect(restored.id, 'rem_1');
      expect(restored.priority, PriorityLevel.high);
      expect(restored.repeatInterval, RepeatInterval.daily);
      expect(restored.isCompleted, isFalse);
      expect(restored.isOverdue, isFalse);
    });

    test('RepeatInterval calculates next daily occurrence correctly', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));
      final nextDaily = RepeatInterval.daily.calculateNextOccurrence(pastTime);

      expect(nextDaily.isAfter(DateTime.now()), isTrue);
      expect(nextDaily.hour, pastTime.hour);
      expect(nextDaily.minute, pastTime.minute);
    });

    test('RepeatInterval recognizes and advances hourly reminders', () {
      final pastHour = DateTime.now().subtract(const Duration(hours: 2));
      final nextHourly = RepeatInterval.hourly.calculateNextOccurrence(pastHour);

      expect(RepeatInterval.fromString('hourly'), RepeatInterval.hourly);
      expect(RepeatInterval.hourly.label, 'Hourly');
      expect(nextHourly.isAfter(pastHour), isTrue);
    });

    test('Reminder handles Google Calendar sync fields correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'rem_cal_1',
        title: 'Doctor Appointment',
        scheduledTime: now.add(const Duration(days: 2)),
        createdAt: now,
        calendarEventId: 'gcal_event_9988',
        calendarId: 'primary_google_cal',
        lastSyncedAt: now,
        isSyncedFromCalendar: true,
      );

      expect(reminder.isCalendarSynced, isTrue);
      expect(reminder.isSyncedFromCalendar, isTrue);
      expect(reminder.calendarEventId, 'gcal_event_9988');

      final json = reminder.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored.calendarEventId, 'gcal_event_9988');
      expect(restored.calendarId, 'primary_google_cal');
      expect(restored.isSyncedFromCalendar, isTrue);
    });
  });

  group('PriorityLevel Tests', () {
    test('Priority levels have appropriate labels and colors', () {
      expect(PriorityLevel.high.label, 'Urgent');
      expect(PriorityLevel.medium.label, 'Medium');
      expect(PriorityLevel.low.label, 'Low');

      expect(PriorityLevel.fromString('high'), PriorityLevel.high);
      expect(PriorityLevel.fromString('invalid'), PriorityLevel.medium);
    });
  });

  group('HomeScreen, Header Actions & Footer Widget Tests', () {
    testWidgets('HomeScreen renders tabs and Built by punpun footer without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = await StorageService.init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MindFlowApp(isFirstLaunch: false),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Built by punpun'), findsOneWidget);
      expect(find.text('Reminders'), findsWidgets);
      expect(find.text('Notes'), findsWidgets);
      expect(find.text('Library'), findsWidgets);
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
      expect(find.byIcon(Icons.dark_mode_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Theme toggle switches theme mode correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = await StorageService.init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MindFlowApp(isFirstLaunch: false),
        ),
      );

      await tester.pumpAndSettle();

      // Tap theme toggle in header
      await tester.tap(find.byIcon(Icons.dark_mode_rounded).first);
      await tester.pumpAndSettle();

      // Now in dark mode, icon should be light_mode_rounded
      expect(find.byIcon(Icons.light_mode_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}


