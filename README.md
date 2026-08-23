# 📓 FlowNotes – Daily Reminders & Smart Notes

A beautiful cross-platform Flutter application for daily reminders, rich note-taking, and bidirectional Google Calendar synchronization. Built with Flutter 3.47.0 and Material Design 3.

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 📝 **Rich Notes** | Markdown toolbar (bold, italic, headers, code, quotes), 7 colour themes, pin to top, tags |
| ✅ **Interactive Checklists** | Convert any note to a checklist with tap-to-complete items |
| ⏰ **Smart Reminders** | Scheduled local notifications with repeat intervals (daily, weekdays, weekly) |
| 🔥 **Priority Levels** | Urgent / Medium / Low with colour-coded badges |
| 📅 **Google Calendar Sync** | Bidirectional — push reminders to Google Calendar, import events into the app |
| 🌙 **Dark / Light Mode** | Switchable theme with persistent preference |
| 🔍 **Search & Filter** | Full-text search and filter by status / priority |
| 📊 **Streak Tracking** | Daily completion streak displayed in the Reminders header |
| 💾 **Offline First** | All data persisted locally with `shared_preferences` |

---

## 🗂️ Project Structure

```
flow_notes_reminders/
├── android/                    # Android platform config
│   └── app/
│       ├── src/main/
│       │   ├── AndroidManifest.xml   # Permissions & receivers
│       │   └── kotlin/.../MainActivity.kt
│       └── build.gradle.kts
├── ios/                        # iOS platform config
│   └── Runner/Info.plist       # Calendar permission descriptions
├── lib/
│   ├── core/
│   │   ├── models/
│   │   │   ├── note.dart              # Note & ChecklistItem models
│   │   │   ├── reminder.dart          # Reminder model (+ calendar sync fields)
│   │   │   ├── priority.dart          # PriorityLevel enum + styling helpers
│   │   │   └── repeat_interval.dart   # RepeatInterval enum + recurrence logic
│   │   ├── services/
│   │   │   ├── storage_service.dart        # Offline JSON persistence
│   │   │   ├── notification_service.dart   # Scheduled local notifications
│   │   │   └── calendar_sync_service.dart  # Google Calendar REST API sync
│   │   └── theme/
│   │       ├── app_colors.dart    # Dark/light palettes + note card colours
│   │       └── app_theme.dart     # Material 3 theme definitions
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── app_providers.dart          # Core service providers
│   │   │   ├── notes_provider.dart         # Notes state notifier
│   │   │   ├── reminders_provider.dart     # Reminders state notifier
│   │   │   ├── calendar_sync_provider.dart # Calendar sync state notifier
│   │   │   └── theme_provider.dart         # Theme mode state
│   │   ├── screens/
│   │   │   ├── home/home_screen.dart           # Root screen + bottom nav
│   │   │   ├── notes/
│   │   │   │   ├── notes_tab.dart              # Notes grid with search
│   │   │   │   └── note_editor_screen.dart     # Full editor with Markdown toolbar
│   │   │   ├── reminders/
│   │   │   │   ├── reminders_tab.dart          # Agenda / upcoming / recurring tabs
│   │   │   │   └── add_edit_reminder_sheet.dart # Bottom sheet for add/edit
│   │   │   └── settings/
│   │   │       └── calendar_sync_dialog.dart   # Google Calendar sync dialog
│   │   └── widgets/
│   │       ├── note_card.dart
│   │       ├── reminder_card.dart
│   │       ├── priority_badge.dart
│   │       ├── streak_header_card.dart
│   │       ├── search_and_filter_bar.dart
│   │       └── color_picker_sheet.dart
│   └── main.dart               # App entry point
├── test/
│   └── widget_test.dart        # Unit & widget tests
└── pubspec.yaml                # Dependencies
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `flutter_local_notifications` | ^22.3.0 | Scheduled alarms & notifications |
| `timezone` | ^0.11.1 | Timezone-aware scheduling |
| `shared_preferences` | ^2.5.5 | Local offline persistence |
| `uuid` | ^4.6.0 | Unique ID generation |
| `intl` | ^0.20.3 | Date/time formatting |
| `google_fonts` | ^8.2.1 | Custom typography |
| `google_sign_in` | ^6.2.2 | Google OAuth2 authentication |
| `googleapis` | ^13.2.0 | Google Calendar REST API |
| `http` | ^1.2.2 | HTTP client for API calls |

---

## ⚙️ Prerequisites

Before running the app, ensure you have the following installed:

### 1. Flutter SDK
- **Location**: `C:\Users\psavl\flutter`
- **Version**: 3.47.0 (stable channel)
- **Dart**: 3.13.0

Verify Flutter is working:
```powershell
flutter doctor
```

### 2. Android Studio
- **Install path**: `C:\Program Files\Android\Android Studio`
- **Bundled JDK (JAVA_HOME)**: `C:\Program Files\Android\Android Studio\jbr`

### 3. Android SDK
- **Location**: `C:\Users\psavl\AppData\Local\Android\Sdk`
- **Components installed**:
  - Android SDK Platform 36
  - Android NDK r28c
  - Build Tools
  - Platform Tools (`adb`)
  - Emulator
  - Command-line Tools (`cmdline-tools/latest`)
  - System Image: `system-images;android-33;google_apis;x86_64`

### 4. Windows Developer Mode
Must be **enabled** for Flutter symlinks to work.
- Open: **Settings → Privacy & Security → For Developers → Developer Mode → ON**
- Or run in PowerShell: `start ms-settings:developers`

---

## 🚀 Running the App — Step by Step

### Step 1 — Open PowerShell and set environment variables

Every new PowerShell session needs these set before running Flutter/ADB commands:

```powershell
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$env:Path;C:\Users\psavl\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\cmdline-tools\latest\bin"
```

> **Tip:** Flutter is already in your permanent user PATH so `flutter` commands work in new terminals. The extra vars above are needed for ADB and SDK tools.

---

### Step 2 — Navigate to the project

```powershell
cd C:\Users\psavl\repositories\flow_notes_reminders
```

---

### Step 3 — Install dependencies

```powershell
flutter pub get
```

---

### Option A: Run on the Android Emulator

#### Start the emulator

```powershell
flutter emulators --launch Pixel5_API33
```

Wait ~60 seconds for the emulator to fully boot (Android home screen appears).

#### Verify the emulator is detected

```powershell
flutter devices
```

You should see `sdk gphone64 x86 64` in the list.

#### Run the app

```powershell
flutter run -d emulator-5554
```

> The first build takes 3–5 minutes (Gradle downloads dependencies). Subsequent runs are much faster.

---

### Option B: Run on a Physical Android Phone (USB)

#### Enable USB Debugging on your phone

1. Open **Settings** on your phone.
2. Go to **About Phone** → tap **Build Number** 7 times rapidly.
3. Go back → you'll now see **Developer Options** in the Settings menu.
4. Open **Developer Options** → enable **USB Debugging**.

#### Connect via USB

Plug your phone into the PC. On your phone, tap **"Allow"** on the USB debugging authorization popup.

#### Verify the phone is detected

```powershell
adb devices
```

Your phone should appear as `<serial>   device`. If it shows `unauthorized`, check your phone screen and tap Allow again.

#### Run the app

```powershell
flutter run
```

Flutter automatically detects and deploys to your connected phone.

---

## 📱 Compiling & Installing an APK on Any Android Phone

### Build a debug APK (for testing)

```powershell
cd C:\Users\psavl\repositories\flow_notes_reminders
flutter build apk --debug
```

APK location after build:
```
build\app\outputs\flutter-apk\app-debug.apk
```

### Build a release APK (for distribution)

```powershell
flutter build apk --release
```

> **Note:** Release builds require a signing key configured in `android/app/build.gradle.kts`. For personal testing, the debug APK works perfectly.

### Install the APK

**Method 1 — via ADB (phone connected via USB):**
```powershell
adb install build\app\outputs\flutter-apk\app-debug.apk
```

**Method 2 — manual install (no cable needed):**
1. Copy `app-debug.apk` to your phone via USB, Google Drive, email, or WhatsApp.
2. On your phone: **Settings → Apps → Special app access → Install unknown apps**
3. Enable installation for your file manager app.
4. Open the APK file on your phone → tap **Install**.

---

## 📅 Google Calendar Sync Setup

1. Open the app → go to the **Reminders** tab → tap the **sync icon** (top right).
2. Tap **"Sign in with Google"** in the dialog.
3. Select your Google account and grant calendar permissions.
4. Choose the target calendar from the list (your primary calendar is auto-selected).
5. Tap **"Sync Now"** to run a full bidirectional sync.

> **Production note:** For a production release, configure an OAuth 2.0 Client ID in the [Google Cloud Console](https://console.cloud.google.com) and register your app's SHA-1 fingerprint. For development/personal use, sign-in works with your own Google account without extra setup.

---

## 🔔 Android Permissions

The app requests the following permissions (declared in `AndroidManifest.xml`):

| Permission | Purpose |
|------------|---------|
| `POST_NOTIFICATIONS` | Show reminder notifications |
| `RECEIVE_BOOT_COMPLETED` | Reschedule alarms after phone restart |
| `SCHEDULE_EXACT_ALARM` | Precise alarm timing |
| `USE_EXACT_ALARM` | Android 13+ exact alarm permission |
| `VIBRATE` | Notification vibration |
| `WAKE_LOCK` | Keep CPU awake for alarm delivery |
| `READ_CALENDAR` | Read Google Calendar events |
| `WRITE_CALENDAR` | Create/update calendar events |
| `INTERNET` | Google Calendar API calls |

---

## 🧪 Running Tests

```powershell
flutter test
```

All 5 unit tests should pass (models, storage, notification scheduling).

---

## 🛠️ Troubleshooting

| Issue | Fix |
|-------|-----|
| `flutter` not recognized | Open a new terminal (PATH was updated) or run `$env:Path = "$env:Path;C:\Users\psavl\flutter\bin"` |
| `JAVA_HOME is not set` | Run `$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"` |
| `no emulators found` | Make sure the emulator window is open and booted. Check with `adb devices` |
| `Gradle build failed` | Run `flutter clean` then `flutter pub get` then `flutter run` again |
| Symlink support warning | Enable **Windows Developer Mode** in Settings |
| `jcenter()` build error | Outdated — project now uses `googleapis` (device_calendar was removed) |
| Google Sign-In fails | Ensure device has Google Play Services and internet access |
| APK won't install | Enable "Install unknown apps" for your file manager in phone settings |
| Emulator is very slow | Enable **Hyper-V** in Windows Features, or use a physical device instead |

---

## 🔄 Quick Reference Commands

```powershell
# Check setup is correct
flutter doctor -v

# Install / update dependencies
flutter pub get

# Launch emulator
flutter emulators --launch Pixel5_API33

# Run on emulator
flutter run -d emulator-5554

# Run on connected phone (auto-detects)
flutter run

# Build debug APK
flutter build apk --debug

# Install APK via ADB
adb install build\app\outputs\flutter-apk\app-debug.apk

# Clean build cache (fixes most strange errors)
flutter clean
flutter pub get

# Run all tests
flutter test

# Analyze code for issues
flutter analyze
```

---

## 📋 Environment Paths Reference

| Item | Path |
|------|------|
| Flutter SDK | `C:\Users\psavl\flutter` |
| Flutter binary | `C:\Users\psavl\flutter\bin\flutter.bat` |
| Android SDK | `C:\Users\psavl\AppData\Local\Android\Sdk` |
| ADB binary | `C:\Users\psavl\AppData\Local\Android\Sdk\platform-tools\adb.exe` |
| Emulator binary | `C:\Users\psavl\AppData\Local\Android\Sdk\emulator\emulator.exe` |
| Java / JDK | `C:\Program Files\Android\Android Studio\jbr` |
| Android Studio | `C:\Program Files\Android\Android Studio` |
| Project root | `C:\Users\psavl\repositories\flow_notes_reminders` |
| Emulator AVD name | `Pixel5_API33` (Pixel 5, Android 13 / API 33, x86_64) |

---

*FlowNotes v1.0.0 — Generated August 2026*
