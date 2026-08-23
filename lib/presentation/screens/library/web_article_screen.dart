import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/web_article.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/web_articles_provider.dart';
import '../../providers/notes_provider.dart';
import '../notes/note_editor_screen.dart';

class WebArticleScreen extends ConsumerStatefulWidget {
  const WebArticleScreen({super.key, required this.article});
  final WebArticle article;

  @override
  ConsumerState<WebArticleScreen> createState() => _WebArticleScreenState();
}

class _WebArticleScreenState extends ConsumerState<WebArticleScreen> {
  final _scrollController = ScrollController();
  double _fontSize = 16.0;
  bool _focusMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_trackProgress);
  }

  void _trackProgress() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
    ref.read(webArticlesProvider.notifier).updateProgress(widget.article.id, progress);
  }

  void _openLinkedNote() {
    final noteId = widget.article.linkedNoteId;
    if (noteId != null) {
      final note = ref.read(notesProvider.notifier).getNoteById(noteId);
      if (note != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NoteEditorScreen(initialNote: note),
        ));
        return;
      }
    }
    // Create a new linked note
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          linkedSourceId: widget.article.id,
          initialTitle: widget.article.title,
          initialContent: '## Notes on: ${widget.article.title}\n\nSource: ${widget.article.url}\n\n',
        ),
      ),
    ).then((noteId) async {
      if (noteId is String) {
        await waitForRouteExit();
        if (mounted) {
          ref.read(webArticlesProvider.notifier).setLinkedNote(widget.article.id, noteId);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_trackProgress);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = ref.watch(webArticlesProvider)
        .firstWhere((a) => a.id == widget.article.id, orElse: () => widget.article);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _focusMode
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              actions: [
                // Font size
                IconButton(
                  icon: const Icon(Icons.text_fields_rounded),
                  tooltip: 'Font size',
                  onPressed: () {
                    setState(() {
                      _fontSize = _fontSize >= 20 ? 14 : _fontSize + 2;
                    });
                  },
                ),
                // Linked note
                IconButton(
                  icon: Icon(
                    article.linkedNoteId != null
                        ? Icons.note_rounded
                        : Icons.note_add_rounded,
                    color: article.linkedNoteId != null ? AppColors.primary : null,
                  ),
                  tooltip: article.linkedNoteId != null ? 'Open linked note' : 'Create note',
                  onPressed: _openLinkedNote,
                ),
                // Focus mode
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Focus mode',
                  onPressed: () => setState(() => _focusMode = true),
                ),
              ],
            ),
      body: Stack(
        children: [
          // Reading progress bar at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: article.readProgress,
              minHeight: 3,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),

          // Article content
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              24,
              _focusMode ? MediaQuery.paddingOf(context).top + 16 : 20,
              24,
              80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: _fontSize + 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (article.author != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'By ${article.author}',
                    style: TextStyle(
                      fontSize: _fontSize - 2,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  article.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _fontSize - 4,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
                const SizedBox(height: 24),

                // Article content
                SelectableText(
                  article.extractedContent,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.7,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Focus mode exit button
          if (_focusMode)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                  tooltip: 'Exit focus mode',
                  onPressed: () => setState(() => _focusMode = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
