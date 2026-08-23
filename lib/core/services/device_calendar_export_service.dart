import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../models/reminder.dart';

class DeviceCalendarExportResult {
  const DeviceCalendarExportResult({
    required this.reminders,
    required this.exportedCount,
    this.errorMessage,
  });

  final List<Reminder> reminders;
  final int exportedCount;
  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

/// Writes reminders to the phone's calendar provider without a Google OAuth
/// token. A Google account already configured on Android handles cloud sync.
class DeviceCalendarExportService {
  final DeviceCalendar _calendar = DeviceCalendar.instance;

  Future<DeviceCalendarExportResult> exportReminders(List<Reminder> reminders) async {
    try {
      final permission = await _calendar.requestPermissions();
      if (permission != CalendarPermissionStatus.granted) {
        return DeviceCalendarExportResult(
          reminders: reminders,
          exportedCount: 0,
          errorMessage: 'Full calendar permission was not granted.',
        );
      }

      final writable = (await _calendar.listCalendars())
          .where((calendar) => !calendar.readOnly && !calendar.hidden)
          .toList();
      Calendar? target;
      for (final calendar in writable) {
        if (calendar.accountType?.toLowerCase().contains('google') == true &&
            calendar.isPrimary) {
          target = calendar;
          break;
        }
      }
      for (final calendar in writable) {
        if (target == null &&
            calendar.accountType?.toLowerCase().contains('google') == true) {
          target = calendar;
        }
        if (target == null && calendar.isPrimary) target = calendar;
      }
      target ??= writable.isNotEmpty ? writable.first : null;
      if (target == null) {
        return DeviceCalendarExportResult(
          reminders: reminders,
          exportedCount: 0,
          errorMessage: 'No writable phone calendar was found.',
        );
      }

      var exported = 0;
      final updated = <Reminder>[];
      for (final reminder in reminders) {
        if (reminder.isCompleted) {
          updated.add(reminder);
          continue;
        }

        final description = reminder.description.isEmpty
            ? 'Created by MindFlow'
            : '${reminder.description}\n\nCreated by MindFlow';
        final end = reminder.scheduledTime.add(const Duration(minutes: 30));
        String? eventId;
        if (reminder.deviceCalendarId == target.id &&
            reminder.deviceCalendarEventId != null) {
          await _calendar.updateEvent(
            eventId: reminder.deviceCalendarEventId!,
            title: reminder.title,
            startDate: reminder.scheduledTime,
            endDate: end,
            description: Patch.set(description),
          );
          eventId = reminder.deviceCalendarEventId;
        } else {
          eventId = await _calendar.createEvent(
            calendarId: target.id,
            title: reminder.title,
            description: description,
            startDate: reminder.scheduledTime,
            endDate: end,
          );
        }

        updated.add(reminder.copyWith(
          deviceCalendarEventId: eventId,
          deviceCalendarId: target.id,
        ));
        exported++;
      }

      return DeviceCalendarExportResult(
        reminders: updated,
        exportedCount: exported,
        errorMessage: exported == 0 && reminders.any((reminder) => !reminder.isCompleted)
            ? 'No active reminders could be written to ${target.name}.'
            : null,
      );
    } catch (error) {
      return DeviceCalendarExportResult(
        reminders: reminders,
        exportedCount: 0,
        errorMessage: 'Device calendar export failed: $error',
      );
    }
  }
}
