# MindFlow — Agent Knowledge Base

Last updated: 2026-08-16

## Project snapshot

- Flutter application for reminders, notes, PDF reading, and calendar export.
- Android application ID: `com.antigravity.flow_notes_reminders`.
- Current version: `1.5.0+10` (set in `pubspec.yaml`).
- Android minimum SDK: 24 (Android 7.0), required by `device_calendar_plus`.
- Local persistence uses `SharedPreferences` through `lib/core/services/storage_service.dart`.

## Main areas

| Area | Primary files | Notes |
| --- | --- | --- |
| Reminders | `lib/presentation/providers/reminders_provider.dart` | Saves before updating state; shows persistence errors. |
| Notifications | `lib/core/services/notification_service.dart` | Local notifications, device timezone, Android permission/exact-alarm handling. |
| Notes | `lib/presentation/providers/notes_provider.dart` | Notes and checklists stored locally. |
| PDF library | `lib/presentation/screens/library/` | Imports a PDF into app storage and remembers the last read page. |
| Calendar | `lib/core/services/calendar_sync_service.dart` | Google REST API sync path; needs OAuth configuration. |
| Phone calendar workaround | `lib/core/services/device_calendar_export_service.dart` | OAuth-free, one-way export to the device calendar. |
| UI theme | `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart` | Sage/clay/warm-paper palette; Nunito Sans typography. |

## Reminders and notifications

- `Reminder` model: `lib/core/models/reminder.dart`.
- Repeat modes: once, hourly, daily, weekdays, weekly.
- Hourly reminders start one hour after saving and use periodic local notifications.
- Notification permission is requested when saving a reminder.
- On Android, exact-alarm access is requested; if not granted, the app uses inexact scheduling instead.
- Device timezone is fetched with `flutter_timezone` and applied before scheduling.
- Required Android receiver declarations are present in `android/app/src/main/AndroidManifest.xml`.
- The app stores reminder data even if notification permission is denied.

### Important notification limitations

- These are notification alerts, not a full-screen alarm-clock experience.
- Android OEM battery optimization can still delay background notification delivery.
- Test on a physical device before relying on reminder timing.

## PDF reading library

- Entry point: `Library` tab in `HomeScreen`.
- Import flow copies selected PDFs to the app documents folder under `pdf_library`.
- Metadata is stored as `PdfDocument` records in `SharedPreferences`.
- Reader: `lib/presentation/screens/library/pdf_reader_screen.dart`.
- Reader uses `SfPdfViewer` in `PdfPageLayoutMode.single`, giving one page at a time.
- Users can swipe through pages or use previous/next controls.
- Reading progress is saved on every page change and again on screen disposal.
- Focus mode hides app chrome for distraction-free reading.

## Calendar options

### 1. Google Calendar REST sync

The Google sync dialog can sign in, list calendars, and run bidirectional REST sync.

Files:

- `lib/core/services/calendar_sync_service.dart`
- `lib/presentation/providers/calendar_sync_provider.dart`
- `lib/presentation/screens/settings/calendar_sync_dialog.dart`

Requirements outside the repository:

1. Create/configure a Google Cloud project.
2. Enable Google Calendar API.
3. Configure OAuth consent screen and test users when applicable.
4. Register Android OAuth credentials for package `com.antigravity.flow_notes_reminders` and the signing certificate SHA-1.
5. For production, optionally supply a web server client ID at build time:

   ```powershell
   flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```

The service uses `GoogleSignInAccount.authHeaders` instead of a raw access token. It returns detailed errors in the dialog.

### 2. OAuth-free phone-calendar export

This is the preferred workaround when Google OAuth cannot be configured.

- UI action: **Google Calendar Sync** → **Save to phone calendar**.
- Requires only standard phone calendar permissions.
- Picks the primary Google calendar on the device when available, otherwise another writable calendar.
- The phone's Google Calendar app/account performs its own cloud sync.
- This is **one-way**: MindFlow saves/updates reminders in the device calendar, but does not import edits made in Google Calendar.
- Event IDs are stored in `Reminder.deviceCalendarEventId` and `Reminder.deviceCalendarId`, preventing duplicate events on later exports.

## Android configuration

`android/app/src/main/AndroidManifest.xml` includes:

- `INTERNET`
- Calendar read/write permissions
- Notification permission
- Exact-alarm permission
- Notification boot/scheduled receivers

The custom Android launcher vector icon is at:

`android/app/src/main/res/drawable/app_icon.xml`

## UI and branding

- Palette: quiet sage (`primary`), soft clay (`secondary`), dusty blue (`accent`), warm ivory surfaces.
- The Good Morning/Afternoon/Evening card must use `AppColors` values; it previously contained hard-coded purple values and has been corrected.
- Footer mark: `Built by punpun` appears below the app navigation in `lib/presentation/screens/home/home_screen.dart`.

## Building APKs

Use the versioned build helper:

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1 -Mode debug
```

For a release build (currently configured with debug signing until a release keystore is added):

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1 -Mode release
```

The helper:

1. Reads `version: x.y.z+build` from `pubspec.yaml`.
2. Builds the selected APK mode.
3. Copies it to `build/app/outputs/versioned-apk/`.
4. Names it `MindFlow-vx.y.z+build-<mode>.apk`.

Current release artifact:

`build/app/outputs/versioned-apk/MindFlow-v1.5.0+10-release.apk`

## Wikipedia reader

The Library app bar has a **Read Wikipedia** (compass) action that opens an
in-app article search. Selecting a result opens the same paginated, quiet
reading experience as the PDF reader:

- swipe or use the previous/next controls to turn pages;
- use focus mode for distraction-free reading;
- the last page is saved automatically, including after the app is closed;
- up to the 12 most recently opened articles are retained locally to keep
  storage bounded.

The reader additionally supports article topic headings, a jumpable Topics
outline, page bookmarks, and an in-session font-size setting. Saved articles
appear in the Library and can be found from the global app search.

`WikipediaService` uses Wikimedia's current REST page-HTML endpoint and turns
the article into reader-friendly plain text. Search uses the MediaWiki Action
API. Display the visible Wikipedia / CC BY-SA attribution whenever this feature
is changed.

## Search, sync, and notification actions

- Global search and dark/light theme toggle are accessible directly from the top
  AppBar header across all primary tabs.
- The Reminders header provides direct Google Calendar sync (`sync_rounded`) and
  global search without extraneous backup buttons.
- Android reminder notifications provide **Mark Done** and **Snooze 10m**.
  The notification service persists either action through `StorageService` and
  reschedules a snoozed reminder.

## Release builds & signing

- Release APKs are signed with the debug key (no release keystore configured).
- **Release-only crash trap (fixed)**: the home-screen widget (androidx.glance) pulls in
  `androidx.work` (WorkManager). R8 minification runs on release builds and strips Room's
  generated `WorkDatabase` implementation, crashing the app at launch with
  `Failed to create an instance of androidx.work.impl.WorkDatabase` (via
  `androidx.startup.InitializationProvider`). Debug builds never run R8, so they work.
  Fix: keep rules in `android/app/proguard-rules.pro` (androidx.room / androidx.work),
  wired in the `release` buildType of `android/app/build.gradle.kts`.
- Shared APK naming convention: `MindFlow-<version>-release.apk` in the `dist/` folder
  (gitignored).
- Version is managed in `pubspec.yaml`.

## Verification commands

```powershell
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File tool\build_apk.ps1 -Mode release
```

The most recent static analysis and unit-test runs passed. The Wikipedia reader is included in the successfully built versioned release APK above.

## Current follow-up opportunities

1. Configure Google Cloud OAuth if true bidirectional Google Calendar REST sync is needed.
2. Add a user-facing device-calendar picker instead of automatically choosing the primary writable calendar.
3. Add recurrence mapping when exporting repeated reminders to the device calendar.
4. Generate an App Bundle (`flutter build appbundle --release`) for Google Play; the keystore is already configured.
5. Test notification, calendar export, and PDF rendering on a physical Android 7.0+ device.
6. Local backup: the Reminders header has a save button that creates a portable
   JSON snapshot in the app documents folder. Add backup import / file sharing
   when a dedicated external-storage or sharing workflow is selected.
7. Global search is available from the top AppBar and searches reminders,
   notes, PDFs, and saved Wikipedia articles.
8. The palette is neutral slate / grey rather than sage green. Wikipedia
   search uses a 320 ms debounced autocomplete list backed by MediaWiki's
   prefix-search endpoint.
9. Global Search and Dark Mode toggle live cleanly in the top AppBars for intuitive
   mobile UX. The bottom navigation bar is streamlined purely for 3-tab navigation
   with the signature `Built by punpun` footer mark below.
