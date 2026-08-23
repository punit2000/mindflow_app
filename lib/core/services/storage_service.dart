import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/priority.dart';
import '../models/reminder.dart';
import '../models/repeat_interval.dart';
import '../models/pdf_document.dart';
import '../models/web_article.dart';
import '../models/wikipedia_article.dart';
import '../models/home_layout.dart';
import '../models/rss_feed.dart';
import '../models/reading_topic.dart';
import '../models/youtube_video.dart';

class StorageService {
  static const String _notesKey = 'flow_notes_data_v1';
  static const String _remindersKey = 'flow_reminders_data_v1';
  static const String _themeKey = 'flow_theme_mode_v1';
  static const String _pdfLibraryKey = 'flow_pdf_library_v1';
  static const String _wikipediaLibraryKey = 'flow_wikipedia_library_v1';
  static const String _firstLaunchKey = 'flow_first_launch_v1';
  static const String _webArticlesKey = 'flow_web_articles_v1';
  static const String _focusModeUntilKey = 'flow_focus_mode_until_v1';
  static const String _focusBlockedPackagesKey = 'flow_focus_blocked_packages_v1';
  static const String _digestEnabledKey = 'flow_digest_enabled_v1';
  static const String _digestHourKey = 'flow_digest_hour_v1';
  static const String _digestMinuteKey = 'flow_digest_minute_v1';
  static const String _homeLayoutKey = 'flow_home_layout_v1';
  static const String _rssFeedsKey = 'flow_rss_feeds_v1';
  static const String _readingTopicsKey = 'flow_reading_topics_v1';
  static const String _youtubeVideosKey = 'flow_youtube_videos_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Notes Operations ---

  List<Note> loadNotes() {
    final String? notesJson = _prefs.getString(_notesKey);
    if (notesJson == null || notesJson.isEmpty) {
      return _getInitialSampleNotes();
    }
    try {
      final List<dynamic> decoded = jsonDecode(notesJson) as List<dynamic>;
      return decoded.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getInitialSampleNotes();
    }
  }

  Future<bool> saveNotes(List<Note> notes) async {
    final String encoded = jsonEncode(notes.map((e) => e.toJson()).toList());
    return await _prefs.setString(_notesKey, encoded);
  }

  // --- Reminders Operations ---

  List<Reminder> loadReminders() {
    final String? remindersJson = _prefs.getString(_remindersKey);
    if (remindersJson == null || remindersJson.isEmpty) {
      return _getInitialSampleReminders();
    }
    try {
      final List<dynamic> decoded = jsonDecode(remindersJson) as List<dynamic>;
      return decoded.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getInitialSampleReminders();
    }
  }

  Future<bool> saveReminders(List<Reminder> reminders) async {
    final String encoded = jsonEncode(reminders.map((e) => e.toJson()).toList());
    return await _prefs.setString(_remindersKey, encoded);
  }

  // --- PDF Library Operations ---

  List<PdfDocument> loadPdfDocuments() {
    final documentsJson = _prefs.getString(_pdfLibraryKey);
    if (documentsJson == null || documentsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(documentsJson) as List<dynamic>;
      return decoded
          .map((item) => PdfDocument.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> savePdfDocuments(List<PdfDocument> documents) {
    final encoded = jsonEncode(documents.map((document) => document.toJson()).toList());
    return _prefs.setString(_pdfLibraryKey, encoded);
  }

  List<WikipediaArticle> loadWikipediaArticles() {
    final articlesJson = _prefs.getString(_wikipediaLibraryKey);
    if (articlesJson == null || articlesJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(articlesJson) as List<dynamic>;
      return decoded
          .map((item) => WikipediaArticle.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveWikipediaArticles(List<WikipediaArticle> articles) {
    final encoded = jsonEncode(articles.map((article) => article.toJson()).toList());
    return _prefs.setString(_wikipediaLibraryKey, encoded);
  }

  // --- Web Articles Operations ---

  List<WebArticle> loadWebArticles() {
    final json = _prefs.getString(_webArticlesKey);
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((item) => WebArticle.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveWebArticles(List<WebArticle> articles) {
    final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
    return _prefs.setString(_webArticlesKey, encoded);
  }

  // --- YouTube Videos Operations ---

  List<YoutubeVideo> loadYoutubeVideos() {
    final json = _prefs.getString(_youtubeVideosKey);
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((item) => YoutubeVideo.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveYoutubeVideos(List<YoutubeVideo> videos) {
    final encoded = jsonEncode(videos.map((v) => v.toJson()).toList());
    return _prefs.setString(_youtubeVideosKey, encoded);
  }

  // --- First Launch ---

  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setLaunched() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  // --- Focus Mode ---

  DateTime? loadFocusModeUntil() {
    final val = _prefs.getString(_focusModeUntilKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  Future<void> saveFocusModeUntil(DateTime? until) async {
    if (until == null) {
      await _prefs.remove(_focusModeUntilKey);
    } else {
      await _prefs.setString(_focusModeUntilKey, until.toIso8601String());
    }
  }

  List<String> loadFocusBlockedPackages() =>
      _prefs.getStringList(_focusBlockedPackagesKey) ?? [];

  Future<void> saveFocusBlockedPackages(List<String> packages) =>
      _prefs.setStringList(_focusBlockedPackagesKey, packages);

  // --- Daily Digest Settings ---

  bool loadDigestEnabled() => _prefs.getBool(_digestEnabledKey) ?? false;
  Future<bool> saveDigestEnabled(bool enabled) => _prefs.setBool(_digestEnabledKey, enabled);

  int loadDigestHour() => _prefs.getInt(_digestHourKey) ?? 8;
  int loadDigestMinute() => _prefs.getInt(_digestMinuteKey) ?? 0;
  Future<void> saveDigestTime(int hour, int minute) async {
    await _prefs.setInt(_digestHourKey, hour);
    await _prefs.setInt(_digestMinuteKey, minute);
  }

  // --- Home Layout ---

  HomeLayout loadHomeLayout() {
    final val = _prefs.getString(_homeLayoutKey);
    if (val == null || val.isEmpty) return HomeLayout.defaultLayout();
    try {
      return HomeLayout.fromJson(jsonDecode(val) as Map<String, dynamic>);
    } catch (_) {
      return HomeLayout.defaultLayout();
    }
  }

  Future<bool> saveHomeLayout(HomeLayout layout) async {
    return _prefs.setString(_homeLayoutKey, jsonEncode(layout.toJson()));
  }

  // --- RSS Feeds ---

  List<RssFeed> loadRssFeeds() {
    final json = _prefs.getString(_rssFeedsKey);
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((e) => RssFeed.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveRssFeeds(List<RssFeed> feeds) {
    final encoded = jsonEncode(feeds.map((f) => f.toJson()).toList());
    return _prefs.setString(_rssFeedsKey, encoded);
  }

  /// Writes a portable, read-only JSON snapshot. PDF files themselves stay in
  /// the app library; the backup includes their titles and reading progress.
  Future<File> exportBackup() async {
    final documents = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${documents.path}${Platform.pathSeparator}mindflow-backup-$stamp.json');
    final payload = {
      'format': 'mindflow-backup-v1',
      'createdAt': DateTime.now().toIso8601String(),
      'notes': _prefs.getString(_notesKey),
      'reminders': _prefs.getString(_remindersKey),
      'pdfLibrary': _prefs.getString(_pdfLibraryKey),
      'wikipediaLibrary': _prefs.getString(_wikipediaLibraryKey),
      'youtubeVideos': _prefs.getString(_youtubeVideosKey),
      'themeMode': _prefs.getString(_themeKey),
    };
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  // --- Theme Mode ---

  String? loadThemeMode() {
    return _prefs.getString(_themeKey);
  }

  Future<bool> saveThemeMode(String mode) async {
    return await _prefs.setString(_themeKey, mode);
  }

  // Initial starter data for first-time launch
  List<Note> _getInitialSampleNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: 'sample_note_1',
        title: '✨ Welcome to MindFlow!',
        content: 'Your intuitive companion for daily notes, ideas, and scheduled reminders.\n\n'
            '• Tap **+** to add a new note or reminder\n'
            '• Swipe cards to complete or delete\n'
            '• Color-code and tag your thoughts\n'
            '• Supports checklists & full markdown styling!',
        colorIndex: 1, // Soft Lavender
        tags: const ['Getting Started', 'Tips'],
        isPinned: true,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Note(
        id: 'sample_note_2',
        title: '🎯 Weekly Sprint Goals',
        content: 'Key deliverables for this sprint:\n\n'
            '1. Complete Flutter app architecture\n'
            '2. Test background notifications & alarms\n'
            '3. Polish Material 3 Dark theme & animations',
        colorIndex: 2, // Mint Fresh
        tags: const ['Work', 'Goals'],
        isPinned: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Note(
        id: 'sample_note_3',
        title: '🛒 Weekend Grocery List',
        content: 'Items to grab from the farmers market',
        colorIndex: 4, // Golden Sun
        tags: const ['Personal', 'Shopping'],
        isPinned: false,
        isChecklist: true,
        checklistItems: const [
          ChecklistItem(id: 'c1', text: 'Almond milk & Greek yogurt', isChecked: true),
          ChecklistItem(id: 'c2', text: 'Fresh avocados & sourdough', isChecked: false),
          ChecklistItem(id: 'c3', text: 'Dark roast coffee beans', isChecked: false),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  List<Reminder> _getInitialSampleReminders() {
    final now = DateTime.now();
    return [
      Reminder(
        id: 'sample_rem_1',
        title: '💧 Hydrate & Quick Stretch',
        description: 'Drink 500ml water and do 2 minutes posture stretch',
        scheduledTime: DateTime(now.year, now.month, now.day, 10, 0),
        repeatInterval: RepeatInterval.daily,
        priority: PriorityLevel.medium,
        tags: const ['Health', 'Daily'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Reminder(
        id: 'sample_rem_2',
        title: '🚀 Team Standup & Sync',
        description: 'Review daily blockers and today’s sprint roadmap',
        scheduledTime: DateTime(now.year, now.month, now.day, 11, 30),
        repeatInterval: RepeatInterval.weekdays,
        priority: PriorityLevel.high,
        tags: const ['Work'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Reminder(
        id: 'sample_rem_3',
        title: '📚 Evening Reading (20 mins)',
        description: 'Read 1 chapter of Atomic Habits',
        scheduledTime: DateTime(now.year, now.month, now.day, 21, 30),
        repeatInterval: RepeatInterval.daily,
        priority: PriorityLevel.low,
        tags: const ['Habits'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  // --- Reading Topics ---

  List<ReadingTopic> loadReadingTopics() {
    final String? json = _prefs.getString(_readingTopicsKey);
    if (json == null || json.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((e) => ReadingTopic.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveReadingTopics(List<ReadingTopic> topics) async {
    final String encoded = jsonEncode(topics.map((e) => e.toJson()).toList());
    return await _prefs.setString(_readingTopicsKey, encoded);
  }
}
