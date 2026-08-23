import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/wikipedia_article.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/notes_provider.dart';
import '../../providers/wikipedia_provider.dart';
import '../notes/note_editor_screen.dart';

class WikipediaReaderScreen extends ConsumerStatefulWidget {
  const WikipediaReaderScreen({super.key, required this.article});
  final WikipediaArticle article;

  @override
  ConsumerState<WikipediaReaderScreen> createState() => _WikipediaReaderScreenState();
}

class _WikipediaReaderScreenState extends ConsumerState<WikipediaReaderScreen> {
  static const String _prefFontSizeKey = 'wiki_reader_font_size';
  static const String _prefFontFamilyKey = 'wiki_reader_font_family';
  static const String _prefThemeKey = 'wiki_reader_theme';

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<String> _pages;
  late final List<_ArticleSection> _sections;
  late final PageController _pageController;
  late int _currentPage;
  late List<int> _bookmarks;
  late int _wordCount;
  late int _estimatedMinutes;
  bool _focusMode = false;
  double _fontSize = 18;
  String _fontFamily = 'Lora'; // 'Lora', 'Nunito Sans', 'Merriweather'
  String _readerTheme = 'system'; // 'system', 'sepia', 'dark', 'light'

  @override
  void initState() {
    super.initState();
    _wordCount = _countWords(widget.article.content);
    _estimatedMinutes = math.max(1, (_wordCount / 200).ceil());
    _pages = _paginate(widget.article.content);
    _sections = _buildSections(_pages);
    _currentPage = math.min(widget.article.lastReadPage, _pages.length - 1);
    _bookmarks = [...widget.article.bookmarkedPages]..sort();
    _pageController = PageController(initialPage: _currentPage);
    _loadPreferences();
    final notifier = ref.read(wikipediaLibraryProvider.notifier);
    final article = widget.article;
    waitForRouteExit().then((_) {
      notifier.saveArticle(article);
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _fontSize = prefs.getDouble(_prefFontSizeKey) ?? 18.0;
          _fontFamily = prefs.getString(_prefFontFamilyKey) ?? 'Lora';
          _readerTheme = prefs.getString(_prefThemeKey) ?? 'system';
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefFontSizeKey, _fontSize);
      await prefs.setString(_prefFontFamilyKey, _fontFamily);
      await prefs.setString(_prefThemeKey, _readerTheme);
    } catch (_) {}
  }

  int _countWords(String content) {
    if (content.isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final article = _currentArticle;
    final notifier = ref.read(wikipediaLibraryProvider.notifier);
    waitForRouteExit().then((_) {
      notifier.saveArticle(article);
    });
    _pageController.dispose();
    super.dispose();
  }

  List<String> _paginate(String content) {
    final blocks = content.split(RegExp(r'\n\s*\n')).where((item) => item.trim().isNotEmpty);
    final pages = <String>[];
    var buffer = StringBuffer();
    for (final block in blocks) {
      final isHeading = block.trimLeft().startsWith('## ');
      if (buffer.isNotEmpty && (isHeading || buffer.length + block.length > 1050)) {
        pages.add(buffer.toString().trim());
        buffer = StringBuffer();
      }
      buffer.writeln(block.trim());
      buffer.writeln();
    }
    if (buffer.isNotEmpty) pages.add(buffer.toString().trim());
    return pages.isEmpty ? ['No readable article text was returned.'] : pages;
  }

  List<_ArticleSection> _buildSections(List<String> pages) {
    final sections = <_ArticleSection>[];
    for (var page = 0; page < pages.length; page++) {
      final match = RegExp(r'^##\s+(.+)$', multiLine: true).firstMatch(pages[page]);
      if (match != null) sections.add(_ArticleSection(match.group(1)!.trim(), page));
    }
    return sections;
  }

  WikipediaArticle get _currentArticle => widget.article.copyWith(
        lastReadPage: _currentPage,
        lastOpenedAt: DateTime.now(),
        bookmarkedPages: _bookmarks,
      );

  void _saveProgress() => ref.read(wikipediaLibraryProvider.notifier).saveArticle(_currentArticle);

  void _turnPage(int direction) {
    final target = (_currentPage + direction).clamp(0, _pages.length - 1);
    if (target != _currentPage) {
      _pageController.animateToPage(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _goToPage(int page) {
    Navigator.pop(context);
    waitForRouteExit().then((_) {
      if (mounted) {
        setState(() => _currentPage = page);
        _pageController.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        _saveProgress();
      }
    });
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
      }
    });
    _saveProgress();
  }

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    SystemChrome.setEnabledSystemUIMode(_focusMode ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  void _createLinkedNote() {
    final linkedNoteId = widget.article.linkedNoteId;
    if (linkedNoteId != null) {
      final existing = ref.read(notesProvider.notifier).getNoteById(linkedNoteId);
      if (existing != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: existing)),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          linkedSourceId: 'wiki_${widget.article.title}',
          initialTitle: widget.article.title,
          initialContent: '## Notes on: ${widget.article.title}\n\n',
        ),
      ),
    ).then((noteId) async {
      if (noteId is String) {
        await waitForRouteExit();
        if (mounted) {
          ref
              .read(wikipediaLibraryProvider.notifier)
              .setLinkedNote(widget.article, noteId);
        }
      }
    });
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_readerTheme) {
      case 'sepia':
        return const Color(0xFFFBF0D9);
      case 'dark':
        return const Color(0xFF12161A);
      case 'light':
        return const Color(0xFFFFFFFF);
      case 'system':
      default:
        return isDark ? AppColors.darkBackground : AppColors.lightBackground;
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_readerTheme) {
      case 'sepia':
        return const Color(0xFF382F24);
      case 'dark':
        return const Color(0xFFF1F5F9);
      case 'light':
        return const Color(0xFF1E293B);
      case 'system':
      default:
        return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }
  }

  Color _getSecondaryTextColor(BuildContext context) {
    switch (_readerTheme) {
      case 'sepia':
        return const Color(0xFF6B5E4A);
      case 'dark':
        return const Color(0xFF94A3B8);
      case 'light':
        return const Color(0xFF64748B);
      case 'system':
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
    }
  }

  TextStyle _getBodyTextStyle(BuildContext context) {
    final textColor = _getTextColor(context);
    switch (_fontFamily) {
      case 'Nunito Sans':
        return GoogleFonts.nunitoSans(fontSize: _fontSize, height: 1.72, color: textColor);
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: _fontSize, height: 1.76, color: textColor);
      case 'Lora':
      default:
        return GoogleFonts.lora(fontSize: _fontSize, height: 1.74, color: textColor);
    }
  }

  TextStyle _getHeadingTextStyle(BuildContext context) {
    final textColor = _getTextColor(context);
    switch (_fontFamily) {
      case 'Nunito Sans':
        return GoogleFonts.nunitoSans(fontSize: _fontSize + 5, fontWeight: FontWeight.w800, height: 1.25, color: textColor);
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: _fontSize + 5, fontWeight: FontWeight.w700, height: 1.28, color: textColor);
      case 'Lora':
      default:
        return GoogleFonts.lora(fontSize: _fontSize + 5, fontWeight: FontWeight.w700, height: 1.25, color: textColor);
    }
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reading Experience',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${_fontSize.round()} px',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Font Size Section
                const Text('Text Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      tooltip: 'Decrease font size',
                      onPressed: _fontSize > 14
                          ? () {
                              setState(() => _fontSize = math.max(14, _fontSize - 1));
                              setSheetState(() {});
                              _savePreferences();
                            }
                          : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 14,
                        max: 26,
                        divisions: 12,
                        label: '${_fontSize.round()} px',
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                          setSheetState(() {});
                          _savePreferences();
                        },
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      tooltip: 'Increase font size',
                      onPressed: _fontSize < 26
                          ? () {
                              setState(() => _fontSize = math.min(26, _fontSize + 1));
                              setSheetState(() {});
                              _savePreferences();
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Font Family Section
                const Text('Typeface', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFontChip('Lora', 'Serif', setSheetState),
                    const SizedBox(width: 8),
                    _buildFontChip('Nunito Sans', 'Sans', setSheetState),
                    const SizedBox(width: 8),
                    _buildFontChip('Merriweather', 'Editorial', setSheetState),
                  ],
                ),
                const SizedBox(height: 18),

                // Reading Theme Section
                const Text('Paper Theme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildThemeCard('system', 'System', Icons.brightness_auto_rounded, isDark ? const Color(0xFF1A2027) : const Color(0xFFF6F8FA), setSheetState),
                    _buildThemeCard('sepia', 'Sepia', Icons.menu_book_rounded, const Color(0xFFFBF0D9), setSheetState),
                    _buildThemeCard('dark', 'Night', Icons.dark_mode_rounded, const Color(0xFF12161A), setSheetState),
                    _buildThemeCard('light', 'White', Icons.light_mode_rounded, const Color(0xFFFFFFFF), setSheetState),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontChip(String family, String label, StateSetter setSheetState) {
    final isSelected = _fontFamily == family;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _fontFamily = family);
          setSheetState(() {});
          _savePreferences();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(String themeKey, String label, IconData icon, Color color, StateSetter setSheetState) {
    final isSelected = _readerTheme == themeKey;
    final cardTextColor = color.computeLuminance() > 0.5
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _readerTheme = themeKey);
            setSheetState(() {});
            _savePreferences();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightCardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: cardTextColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: cardTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);
    final secondaryTextColor = _getSecondaryTextColor(context);
    final isBookmarked = _bookmarks.contains(_currentPage);
    final progressPercent = ((_currentPage + 1) / _pages.length * 100).round();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: _focusMode
          ? null
          : AppBar(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textColor),
                  ),
                  Text(
                    '~$_estimatedMinutes min read · $progressPercent% complete',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.format_size_rounded),
                  tooltip: 'Reading settings',
                  onPressed: _showReaderSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted_rounded),
                  tooltip: 'Article topics',
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
                IconButton(
                  icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                  tooltip: 'Bookmark page',
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Focus mode',
                  onPressed: _toggleFocusMode,
                ),
              ],
            ),
      endDrawer: _ArticleOutline(
        title: widget.article.title,
        sections: _sections,
        bookmarks: _bookmarks,
        currentPage: _currentPage,
        estimatedMinutes: _estimatedMinutes,
        onGoToPage: _goToPage,
      ),
      floatingActionButton: null,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              _saveProgress();
            },
            itemBuilder: (context, index) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 70),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0) ...[
                        Text(
                          widget.article.title,
                          style: _getHeadingTextStyle(context).copyWith(fontSize: _fontSize + 11, height: 1.18),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.public_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Wikipedia · CC BY-SA',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              '~$_estimatedMinutes min read',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      _ArticleText(
                        content: _pages[index],
                        bodyStyle: _getBodyTextStyle(context),
                        headingStyle: _getHeadingTextStyle(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_focusMode)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.fullscreen_exit_rounded),
                tooltip: 'Exit Focus mode',
                onPressed: _toggleFocusMode,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(12),
              child: Material(
                color: Theme.of(context).brightness == Brightness.dark &&
                        (_readerTheme == 'system' || _readerTheme == 'dark')
                    ? const Color(0xFF1E2226).withValues(alpha: 0.94)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.94),
                elevation: 3,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0 ? () => _turnPage(-1) : null,
                        icon: Icon(Icons.chevron_left_rounded, color: textColor),
                        tooltip: 'Previous page',
                      ),
                      Text(
                        'Page ${_currentPage + 1} of ${_pages.length} ($progressPercent%)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textColor),
                      ),
                      IconButton(
                        onPressed: _currentPage < _pages.length - 1 ? () => _turnPage(1) : null,
                        icon: Icon(Icons.chevron_right_rounded, color: textColor),
                        tooltip: 'Next page',
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: textColor.withValues(alpha: 0.15),
                      ),
                      IconButton(
                        onPressed: _createLinkedNote,
                        icon: Icon(Icons.edit_note_rounded, color: textColor),
                        tooltip: 'Add note',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleText extends StatelessWidget {
  const _ArticleText({
    required this.content,
    required this.bodyStyle,
    required this.headingStyle,
  });

  final String content;
  final TextStyle bodyStyle;
  final TextStyle headingStyle;

  @override
  Widget build(BuildContext context) {
    final blocks = content.split(RegExp(r'\n\s*\n')).where((block) => block.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: block.trimLeft().startsWith('## ')
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(block.trimLeft().substring(3), style: headingStyle),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                : Text(block.trim(), style: bodyStyle),
          ),
      ],
    );
  }
}

class _ArticleSection {
  const _ArticleSection(this.title, this.page);
  final String title;
  final int page;
}

class _ArticleOutline extends StatelessWidget {
  const _ArticleOutline({
    required this.title,
    required this.sections,
    required this.bookmarks,
    required this.currentPage,
    required this.estimatedMinutes,
    required this.onGoToPage,
  });

  final String title;
  final List<_ArticleSection> sections;
  final List<int> bookmarks;
  final int currentPage;
  final int estimatedMinutes;
  final ValueChanged<int> onGoToPage;

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~$estimatedMinutes min estimated reading time',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (sections.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: Text('Topics', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                ),
                for (final section in sections)
                  ListTile(
                    dense: true,
                    title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    selected: section.page == currentPage,
                    leading: const Icon(Icons.segment_rounded, size: 18),
                    onTap: () => onGoToPage(section.page),
                  ),
              ],
              if (bookmarks.isNotEmpty) ...[
                const Divider(height: 28),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Text('Bookmarks', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                ),
                for (final page in bookmarks)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
                    title: Text('Page ${page + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => onGoToPage(page),
                  ),
              ],
              if (sections.isEmpty && bookmarks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('This article has no detected topic headings yet.'),
                ),
            ],
          ),
        ),
      );
}
