import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/priority.dart';
import '../models/reminder.dart';
import '../models/repeat_interval.dart';

// ---------------------------------------------------------------------------
// HTTP client that injects the GoogleSignIn auth header
// ---------------------------------------------------------------------------
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------
class CalendarSyncResult {
  final List<Reminder> updatedReminders;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;

  const CalendarSyncResult({
    required this.updatedReminders,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
class CalendarSyncService {
  static const _scopes = [gcal.CalendarApi.calendarScope];
  static const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    // An optional registered Web OAuth client ID can be supplied for a
    // production build using --dart-define. Android otherwise uses its
    // package-name/SHA registered client automatically.
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  GoogleSignInAccount? _currentAccount;
  String? _lastError;

  String? get lastError => _lastError;

  // ── Authentication ───────────────────────────────────────────────────────

  /// Signs the user in (or silently re-signs if a token exists).
  Future<bool> signIn() async {
    try {
      _currentAccount = await _googleSignIn.signInSilently();
      _currentAccount ??= await _googleSignIn.signIn();
      if (_currentAccount == null) {
        _lastError = 'Sign-in was cancelled before an account was selected.';
        return false;
      }
      _lastError = null;
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _lastError = 'Google Sign-In error: $e';
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentAccount = null;
  }

  bool get isSignedIn => _currentAccount != null;
  String? get displayName => _currentAccount?.displayName;
  String? get email => _currentAccount?.email;

  Future<gcal.CalendarApi?> _calendarApi() async {
    try {
      final account = _currentAccount ?? await _googleSignIn.signInSilently();
      if (account == null) {
        throw StateError('Sign in to a Google account before syncing.');
      }
      _currentAccount = account;

      // authHeaders is supplied and refreshed by google_sign_in; reading the
      // raw access token here can yield a null or expired token.
      final headers = await account.authHeaders;
      return gcal.CalendarApi(_GoogleAuthClient(headers));
    } catch (e) {
      debugPrint('Calendar API init error: $e');
      _lastError = 'Calendar authorization failed: $e';
      rethrow;
    }
  }

  // ── Calendar helpers ────────────────────────────────────────────────────

  /// Lists all writable calendars in the signed-in account.
  Future<List<gcal.CalendarListEntry>> getAvailableCalendars() async {
    try {
      final api = await _calendarApi();
      if (api == null) return [];
      final list = await api.calendarList.list(minAccessRole: 'writer');
      return list.items ?? [];
    } catch (e) {
      debugPrint('Error listing calendars: $e');
      _lastError = 'Could not load calendars: $e';
      return [];
    }
  }

  /// Pushes a local reminder to Google Calendar (create or update).
  Future<String?> pushReminderToCalendar({
    required Reminder reminder,
    required String calendarId,
  }) async {
    try {
      final api = await _calendarApi();
      if (api == null) return null;

      final start = gcal.EventDateTime(
        dateTime: reminder.scheduledTime.toUtc(),
        timeZone: 'UTC',
      );
      final end = gcal.EventDateTime(
        dateTime: reminder.scheduledTime.add(const Duration(minutes: 30)).toUtc(),
        timeZone: 'UTC',
      );

      final event = gcal.Event(
        summary: reminder.title,
        description: reminder.description.isNotEmpty
            ? reminder.description
            : 'FlowNotes Reminder',
        start: start,
        end: end,
        extendedProperties: gcal.EventExtendedProperties(
          private: {'flowNotesId': reminder.id},
        ),
      );

      if (reminder.calendarEventId != null) {
        // Update existing
        final updated = await api.events.update(event, calendarId, reminder.calendarEventId!);
        return updated.id;
      } else {
        // Create new
        final created = await api.events.insert(event, calendarId);
        return created.id;
      }
    } catch (e) {
      debugPrint('Error pushing reminder to calendar: $e');
      _lastError = 'Could not add “${reminder.title}” to Google Calendar: $e';
      rethrow;
    }
  }

  /// Deletes a Google Calendar event.
  Future<bool> deleteCalendarEvent({
    required String calendarId,
    required String eventId,
  }) async {
    try {
      final api = await _calendarApi();
      if (api == null) return false;
      await api.events.delete(calendarId, eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }

  // ── Bidirectional sync ───────────────────────────────────────────────────

  Future<CalendarSyncResult> syncBidirectional({
    required List<Reminder> localReminders,
    required String calendarId,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) async {
    try {
      final api = await _calendarApi();
      if (api == null) {
        return CalendarSyncResult(
          updatedReminders: localReminders,
          errorMessage: 'Not signed in to Google',
        );
      }

      final now = DateTime.now();
      final start = (windowStart ?? now.subtract(const Duration(days: 7))).toUtc();
      final end = (windowEnd ?? now.add(const Duration(days: 60))).toUtc();

      // 1. Fetch remote events in the time window
      final eventsResource = await api.events.list(
        calendarId,
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );

      final remoteEvents = eventsResource.items ?? [];
      final Map<String, gcal.Event> remoteById = {
        for (final e in remoteEvents)
          if (e.id != null) e.id!: e,
      };

      int pushed = 0;
      int pulled = 0;
      final List<Reminder> updatedList = [];
      final Set<String> matchedIds = {};

      // 2. Push local reminders → Google Calendar
      for (final local in localReminders) {
        if (local.calendarEventId != null && remoteById.containsKey(local.calendarEventId)) {
          // Already synced — check if remote was updated
          final remote = remoteById[local.calendarEventId]!;
          matchedIds.add(remote.id!);

          final remoteTitle = remote.summary ?? local.title;
          final remoteDesc = remote.description ?? local.description;
          final remoteStart = remote.start?.dateTime?.toLocal() ?? local.scheduledTime;

          if (remoteTitle != local.title || remoteStart != local.scheduledTime) {
            // Remote changed → update local (pull)
            updatedList.add(local.copyWith(
              title: remoteTitle,
              description: remoteDesc,
              scheduledTime: remoteStart,
              lastSyncedAt: now,
            ));
            pulled++;
          } else {
            updatedList.add(local.copyWith(lastSyncedAt: now));
          }
        } else if (local.calendarEventId == null && !local.isCompleted) {
          // New local reminder — push to Google Calendar
          final eventId = await pushReminderToCalendar(
            reminder: local,
            calendarId: calendarId,
          );
          if (eventId != null) {
            updatedList.add(local.copyWith(
              calendarEventId: eventId,
              calendarId: calendarId,
              lastSyncedAt: now,
            ));
            pushed++;
          } else {
            updatedList.add(local);
          }
        } else {
          updatedList.add(local);
        }
      }

      // 3. Pull new Google Calendar events → FlowNotes
      final localReminderIds = {
        for (final r in localReminders) if (r.calendarEventId != null) r.calendarEventId!,
      };
      for (final remote in remoteEvents) {
        if (remote.id != null &&
            !localReminderIds.contains(remote.id) &&
            !matchedIds.contains(remote.id)) {
          final eventStart = remote.start?.dateTime?.toLocal() ?? now;
          if (eventStart.isAfter(start.toLocal())) {
            updatedList.add(Reminder(
              id: const Uuid().v4(),
              title: remote.summary?.isNotEmpty == true ? remote.summary! : 'Calendar Event',
              description: remote.description ?? '',
              scheduledTime: eventStart,
              repeatInterval: RepeatInterval.none,
              priority: PriorityLevel.medium,
              tags: const ['Google Calendar'],
              createdAt: now,
              calendarEventId: remote.id,
              calendarId: calendarId,
              lastSyncedAt: now,
              isSyncedFromCalendar: true,
            ));
            pulled++;
          }
        }
      }

      return CalendarSyncResult(
        updatedReminders: updatedList,
        pushedCount: pushed,
        pulledCount: pulled,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      return CalendarSyncResult(
        updatedReminders: localReminders,
        errorMessage: 'Sync failed: $e',
      );
    }
  }
}
