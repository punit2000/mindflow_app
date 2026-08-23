import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../../core/services/calendar_sync_service.dart';
import '../../core/services/device_calendar_export_service.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';
import 'reminders_provider.dart';

enum SyncStatus { idle, syncing, success, error }

class CalendarSyncState {
  final SyncStatus status;
  final String? selectedCalendarId;
  final String? selectedCalendarName;
  final DateTime? lastSyncTime;
  final String? message;
  final List<gcal.CalendarListEntry> availableCalendars;
  final bool isSignedIn;

  const CalendarSyncState({
    this.status = SyncStatus.idle,
    this.selectedCalendarId,
    this.selectedCalendarName,
    this.lastSyncTime,
    this.message,
    this.availableCalendars = const [],
    this.isSignedIn = false,
  });

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasSelectedCalendar => selectedCalendarId != null && selectedCalendarId!.isNotEmpty;

  CalendarSyncState copyWith({
    SyncStatus? status,
    String? selectedCalendarId,
    String? selectedCalendarName,
    DateTime? lastSyncTime,
    String? message,
    List<gcal.CalendarListEntry>? availableCalendars,
    bool? isSignedIn,
  }) {
    return CalendarSyncState(
      status: status ?? this.status,
      selectedCalendarId: selectedCalendarId ?? this.selectedCalendarId,
      selectedCalendarName: selectedCalendarName ?? this.selectedCalendarName,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      message: message,
      availableCalendars: availableCalendars ?? this.availableCalendars,
      isSignedIn: isSignedIn ?? this.isSignedIn,
    );
  }
}

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService();
});

final deviceCalendarExportServiceProvider = Provider<DeviceCalendarExportService>((ref) {
  return DeviceCalendarExportService();
});

final calendarSyncProvider =
    StateNotifierProvider<CalendarSyncNotifier, CalendarSyncState>((ref) {
  final service = ref.watch(calendarSyncServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  final deviceCalendar = ref.watch(deviceCalendarExportServiceProvider);
  return CalendarSyncNotifier(service, deviceCalendar, storage, ref);
});

class CalendarSyncNotifier extends StateNotifier<CalendarSyncState> {
  final CalendarSyncService _service;
  final DeviceCalendarExportService _deviceCalendar;
  final Ref _ref;

  CalendarSyncNotifier(this._service, this._deviceCalendar, StorageService storage, this._ref)
      : super(const CalendarSyncState());

  /// Sign in to Google and load available calendars.
  Future<void> signIn() async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Signing in to Google...');
    final ok = await _service.signIn();
    if (ok) {
      state = state.copyWith(isSignedIn: true, status: SyncStatus.idle, message: null);
      await loadCalendars();
    } else {
      state = state.copyWith(
        isSignedIn: false,
        status: SyncStatus.error,
        message: _service.lastError ?? 'Google Sign-In failed or was cancelled.',
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const CalendarSyncState();
  }

  Future<void> loadCalendars() async {
    final calendars = await _service.getAvailableCalendars();
    state = state.copyWith(availableCalendars: calendars, isSignedIn: true);

    // Auto-select the primary calendar
    if (state.selectedCalendarId == null && calendars.isNotEmpty) {
      final primary = calendars.firstWhere(
        (c) => c.primary == true,
        orElse: () => calendars.first,
      );
      setSelectedCalendar(primary.id ?? 'primary', primary.summary ?? 'Google Calendar');
    }
  }

  void setSelectedCalendar(String id, String name) {
    state = state.copyWith(selectedCalendarId: id, selectedCalendarName: name);
  }

  Future<void> triggerSync() async {
    if (!state.isSignedIn) {
      await signIn();
      if (!state.isSignedIn) return;
    }

    if (!state.hasSelectedCalendar) {
      await loadCalendars();
      if (!state.hasSelectedCalendar) {
        state = state.copyWith(
          status: SyncStatus.error,
          message: _service.lastError ?? 'No writable Google Calendar was found.',
        );
        return;
      }
    }

    state = state.copyWith(status: SyncStatus.syncing, message: 'Syncing with Google Calendar...');

    final currentReminders = _ref.read(remindersProvider);
    final result = await _service.syncBidirectional(
      localReminders: currentReminders,
      calendarId: state.selectedCalendarId!,
    );

    if (result.isSuccess) {
      await _ref.read(remindersProvider.notifier).setRemindersFromSync(result.updatedReminders);
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        message: 'Synced! (+${result.pushedCount} pushed, +${result.pulledCount} imported)',
      );
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        message: result.errorMessage ?? 'Sync failed',
      );
    }
  }

  Future<void> exportToDeviceCalendar() async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Saving to your phone calendar...');
    final result = await _deviceCalendar.exportReminders(_ref.read(remindersProvider));
    if (result.isSuccess) {
      await _ref.read(remindersProvider.notifier).setRemindersFromSync(result.reminders);
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        message: '${result.exportedCount} reminders saved to your phone calendar.',
      );
    } else {
      state = state.copyWith(status: SyncStatus.error, message: result.errorMessage);
    }
  }
}
