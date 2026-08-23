# MindFlow Feature Expansion — XS → M Tier

Implementing all XS, S, and M features across Notes, Reminders, Library, Productivity, and UX. Skipping: Location Reminders, Smart Snooze, Drawing/Sketch.

---

## Open Questions

> [!IMPORTANT]
> **Dark/Light toggle is already fully implemented** via `ThemeToggleAction` in `app_header_actions.dart` — already wired to storage. Marking as ✅ Done, no work needed.

> [!IMPORTANT]
> **Reading progress tracking is also largely done** — `PdfDocument` already has `lastReadPage` + `pageCount`, and `PdfReaderScreen` already calls `saveReadingProgress`. The only missing piece is showing a visual progress bar on the library card. This is a ~15-minute tweak.

> [!NOTE]
> **Note folders** — the `Note` model already has `tags: List<String>`. Rather than adding a separate `folder` field, folders will be implemented as a **special first-tag** convention (e.g. tag prefixed `📁`) OR as a dedicated dropdown. Recommending a clean `folder` field addition to stay explicit.

---

## Phase 1 — XS (< 2h total, mostly already done)

### ✅ Dark/Light Toggle
Already done via `ThemeToggleAction`. **No changes needed.**

---

### Reading Progress Bar on Library Card
**File:** [`library_tab.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/library/library_tab.dart)

#### [MODIFY] library_tab.dart
- Add a thin `LinearProgressIndicator` beneath each PDF card title showing `lastReadPage / pageCount`
- Show "Page X of Y" subtitle text

---

### Markdown Rendering in Note Editor
**Files:** [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart), [`notes_tab.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/notes_tab.dart)

**New package:** `flutter_markdown: ^0.7.x`

#### [MODIFY] note_editor_screen.dart
- Add a **Preview / Edit toggle** button in the AppBar actions
- In preview mode, replace `TextField` with `MarkdownBody(data: _contentController.text)`

#### [MODIFY] notes_tab.dart
- Use `MarkdownBody` for the note card content preview (truncated to 3 lines)

---

## Phase 2 — S (half-day each)

### Note Folders
**Files:** [`note.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/models/note.dart), [`notes_provider.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/providers/notes_provider.dart), [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart), [`notes_tab.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/notes_tab.dart)

#### [MODIFY] note.dart
- Add `folder: String?` field (nullable — null = "All Notes")
- Update `copyWith`, `toJson`, `fromJson`

#### [MODIFY] notes_provider.dart
- Add `filterByFolder(String? folder)` method
- Add `allFolders` getter

#### [MODIFY] note_editor_screen.dart
- Add a folder dropdown/chip row beneath the title field

#### [MODIFY] notes_tab.dart
- Add a horizontal scrollable folder pill-filter row at the top

---

### Note Templates
**Files:** [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart)

**New file:** `lib/core/models/note_template.dart`

#### [NEW] note_template.dart
- Static list of 6 templates: Meeting Notes, Daily Journal, Project Brief, Book Summary, Shopping List (checklist), Habit Tracker

#### [MODIFY] home_screen.dart
- Add "From Template" option to the note type picker bottom sheet

#### [MODIFY] note_editor_screen.dart
- Accept optional `template: NoteTemplate?` param; pre-fill title + content on init

---

### Note Sharing / Export
**New package:** `share_plus: ^11.x`

**Files:** [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart)

#### [MODIFY] note_editor_screen.dart
- Add share icon in AppBar actions
- On tap: `Share.share('${title}\n\n${content}')` — plain text share
- Bonus: "Copy to clipboard" option in the same menu

---

### PDF Bookmarks
**Files:** [`pdf_document.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/models/pdf_document.dart), [`pdf_reader_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/library/pdf_reader_screen.dart), [`pdf_library_provider.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/providers/pdf_library_provider.dart)

#### [MODIFY] pdf_document.dart
- Add `bookmarks: List<int>` field (list of page numbers)
- Update serialization

#### [MODIFY] pdf_reader_screen.dart
- Bookmark icon in AppBar — toggles current page in/out of bookmarks
- Bookmarks drawer/sheet: list of bookmarked pages, tap to jump

#### [MODIFY] pdf_library_provider.dart
- Add `toggleBookmark(String docId, int page)` method

---

### Book/Article Notes (Linked Notes)
**Files:** [`pdf_document.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/models/pdf_document.dart), [`wikipedia_article.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/models/wikipedia_article.dart), [`pdf_reader_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/library/pdf_reader_screen.dart), [`wikipedia_reader_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/library/wikipedia_reader_screen.dart)

#### [MODIFY] pdf_document.dart + wikipedia_article.dart
- Add `linkedNoteId: String?` field

#### [MODIFY] pdf_reader_screen.dart + wikipedia_reader_screen.dart
- Add a "Notes" FAB that opens `NoteEditorScreen` pre-linked to the document
- If a note already exists, open it directly; if not, create a new one with the document title as title

#### [MODIFY] notes_provider.dart
- Add `getNoteById(String id)` method (likely already there or trivial)

---

### Reminder from Note
**Files:** [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart)

#### [MODIFY] note_editor_screen.dart
- Add an "alarm" icon button in the AppBar actions
- Tapping it opens `AddEditReminderSheet.show(context)` with the note title pre-filled as the reminder title

---

### Pomodoro Focus Timer
**New files:** `lib/presentation/screens/reminders/pomodoro_timer_screen.dart`

**New provider:** `lib/presentation/providers/pomodoro_provider.dart`

#### [NEW] pomodoro_provider.dart
- `StateNotifier` managing: `isRunning`, `secondsRemaining`, `phase` (work/short break/long break), `completedSessions`
- Uses `Timer.periodic` for countdown

#### [NEW] pomodoro_timer_screen.dart
- Full-screen timer with animated circular progress arc
- 25/5/15 min phases with subtle color transitions
- Start/pause/reset/skip controls
- Optional notification when phase ends

#### [MODIFY] home_screen.dart
- Add "Focus Timer" option to the FAB creation sheet (or as a dedicated button)

---

### Onboarding Flow
**New file:** `lib/presentation/screens/onboarding/onboarding_screen.dart`

#### [NEW] onboarding_screen.dart
- 4 slides: Welcome, Notes, Reminders, Library — with minimal animated illustrations using `Icons` + `AnimatedContainer`
- "Get Started" button on last slide
- Persists `firstLaunch: false` to SharedPreferences via storage service

#### [MODIFY] storage_service.dart
- Add `isFirstLaunch()` / `setLaunched()` helpers

#### [MODIFY] main.dart
- Check `isFirstLaunch()` before showing `HomeScreen`; route to `OnboardingScreen` if true

---

### Quick Capture (Persistent Notification Action)
**Files:** [`notification_service.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/services/notification_service.dart), [`home_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/home/home_screen.dart)

#### [MODIFY] notification_service.dart
- Register an always-on "Quick Capture" notification (low priority, ongoing) with an action button: "New Note" → deep-link to open editor

#### [MODIFY] main.dart
- Handle notification action tap → navigate to `NoteEditorScreen`

> [!NOTE]
> Alternative simpler approach: add a persistent Quick Capture entry point via a long-press on the FAB. This avoids notification permission complexity and is equally convenient.

---

## Phase 3 — M (1-2 days each)

### Voice-to-Text Notes
**New package:** `speech_to_text: ^7.x`

**Files:** [`note_editor_screen.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/presentation/screens/notes/note_editor_screen.dart), `AndroidManifest.xml`, `Info.plist`

#### [MODIFY] note_editor_screen.dart
- Add microphone button in the bottom toolbar
- While recording: show animated waveform indicator + live transcript appending to `_contentController`
- On stop: finalise and append text

#### [MODIFY] AndroidManifest.xml + Info.plist
- Add `RECORD_AUDIO` permission (Android) and `NSSpeechRecognitionUsageDescription` (iOS)

---

### Focus / DND Mode (Notification Suppression)
**Files:** [`notification_service.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/services/notification_service.dart)

**New file:** `lib/presentation/screens/reminders/focus_mode_screen.dart`

#### [NEW] focus_mode_screen.dart
- Timer selection (15/30/45/60 min or custom)
- While active: shows countdown, "End Focus" button
- Suppresses reminder notifications by checking a `focusModeUntil` timestamp in the notification service before firing

#### [MODIFY] notification_service.dart
- Add `focusModeUntil: DateTime?` check before delivering notifications

#### [MODIFY] storage_service.dart
- Persist `focusModeUntil` timestamp

---

### Web Article Reader
**New package:** `webview_flutter: ^4.x` + `html: ^0.15.x`

**New files:** `lib/presentation/screens/library/web_article_screen.dart`, `lib/core/services/article_extraction_service.dart`

**New model:** `lib/core/models/web_article.dart`

#### [NEW] web_article.dart
- Fields: `id`, `url`, `title`, `extractedContent`, `savedAt`, `readProgress`

#### [NEW] article_extraction_service.dart
- Fetches URL via `http`, parses HTML with `html` package
- Extracts: headline, author, paragraphs (strips nav/ads/scripts)

#### [NEW] web_article_screen.dart
- Clean reader UI with extracted content (font size control, scroll position tracking)
- "Save to Library" button

#### [MODIFY] library_tab.dart
- Add a "Web Articles" section between PDFs and Wikipedia
- URL input FAB action when Library tab is active

#### [MODIFY] storage_service.dart + app_providers.dart
- Add `webArticles` storage key and provider

---

### Stats & Insights
**New package:** `fl_chart: ^0.70.x`

**New files:** `lib/presentation/screens/stats/stats_screen.dart`

#### [NEW] stats_screen.dart
- **Notes stats:** notes created per week (bar chart), tag distribution (pie chart), avg note length
- **Reminders stats:** completion rate, most productive time-of-day, streak
- **Library stats:** PDFs read, Wikipedia articles saved, reading time estimate

#### [MODIFY] home_screen.dart or `app_header_actions.dart`
- Add a stats icon button accessible from the header

---

### Daily Digest Notification
**Files:** [`notification_service.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/services/notification_service.dart), [`storage_service.dart`](file:///c:/Users/psavl/repositories/flow_notes_reminders/lib/core/services/storage_service.dart)

**New file:** `lib/core/services/digest_service.dart`

#### [NEW] digest_service.dart
- Scheduled daily at user-configured time (default 8 AM)
- Builds a summary: "You have X reminders today, Y notes created this week"
- Fires a rich notification with expandable content

#### [MODIFY] notification_service.dart
- Add `scheduleDaily(int hour, int minute, String title, String body)` method

#### [MODIFY] settings screen
- Add "Daily Digest" toggle + time picker

---

## New Packages Summary

| Package | Purpose | Pub.dev |
|---|---|---|
| `flutter_markdown` | Markdown rendering | ✅ Add |
| `share_plus` | Note sharing | ✅ Add |
| `speech_to_text` | Voice-to-text | ✅ Add |
| `fl_chart` | Stats charts | ✅ Add |
| `webview_flutter` | Web article view | ✅ Add |
| `html` | HTML parsing for articles | ✅ Add |

---

## Verification Plan

### Automated
- Run `flutter analyze` after each phase
- Run `flutter test` (existing tests)

### Manual
- Test on Android emulator or physical device for each feature
- Specifically verify: voice permissions, notification delivery, markdown rendering, article extraction

### Order of Implementation
1. **Phase 1 XS** → Reading progress bar, Markdown preview (30 min)
2. **Phase 2 S — Notes** → Folders, Templates, Sharing, Reminder-from-note (2-3h)
3. **Phase 2 S — Library** → PDF Bookmarks, Linked Notes (1-2h)
4. **Phase 2 S — Productivity** → Pomodoro, Onboarding, Quick Capture (2-3h)
5. **Phase 3 M** → Voice Notes, Focus Mode, Web Reader, Stats, Daily Digest (2-3 days)

> After Phase 3 completes, will ask about XL features: Note Linking, Habit Tracker, Home Screen Widgets, PDF Annotations, RSS Reader.
