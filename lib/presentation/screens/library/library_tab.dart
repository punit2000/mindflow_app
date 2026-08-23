import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pdf_document.dart';
import '../../../core/models/web_article.dart';
import '../../../core/models/wikipedia_article.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/pdf_library_provider.dart';
import '../../providers/reading_topics_provider.dart';
import '../../providers/web_articles_provider.dart';
import '../../providers/wikipedia_provider.dart';
import '../../providers/youtube_provider.dart';
import '../../../core/models/youtube_video.dart';
import 'youtube_player_screen.dart';
import '../../widgets/app_header_actions.dart';
import '../settings/settings_screen.dart';
import 'pdf_reader_screen.dart';
import 'rss_feed_list_screen.dart';
import 'web_article_screen.dart';
import 'wikipedia_reader_screen.dart';
import 'wikipedia_search_screen.dart';

/// Selected topic filter in the reading library. `null` = All.
final selectedReadingTopicProvider = StateProvider<String?>((ref) => null);

class LibraryTab extends ConsumerWidget {
  const LibraryTab({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final document = await ref.read(pdfLibraryProvider.notifier).importPdf();
      if (document != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfReaderScreen(document: document)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not import that PDF. Please try another file.')),
        );
      }
    }
  }

  Future<void> _saveWebArticle(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    String? errorText;
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final input = controller.text.trim();
            final uri = Uri.tryParse(input);
            final isValid = uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty;
            if (!isValid) {
              setDialogState(() => errorText = 'Enter a valid http(s) URL');
              return;
            }
            Navigator.pop(dialogContext, input);
          }

          return AlertDialog(
            title: const Text('Save web article'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Article URL',
                hintText: 'https://example.com/article',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Fetch'),
              ),
            ],
          );
        },
      ),
    );

    await waitForRouteExit();
    controller.dispose();

    if (url == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching article…')),
    );
    final notifier = ref.read(webArticlesProvider.notifier);
    final extractor = ref.read(articleExtractionServiceProvider);
    final article = await notifier.fetchAndSave(url, extractor);

    if (!context.mounted) return;
    if (article != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WebArticleScreen(article: article)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load that article. Please check the URL.')),
      );
    }
  }

  Future<void> _saveYoutubeVideo(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    String? errorText;
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final input = controller.text.trim();
            final uri = Uri.tryParse(input);
            final isValid = uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty;
            if (!isValid) {
              setDialogState(() => errorText = 'Enter a valid URL');
              return;
            }
            Navigator.pop(dialogContext, input);
          }

          return AlertDialog(
            title: const Text('Save YouTube video'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'https://youtube.com/watch?v=...',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    await waitForRouteExit();
    controller.dispose();

    if (url == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching video details…')),
    );
    final notifier = ref.read(youtubeProvider.notifier);
    final video = await notifier.fetchAndSave(url);

    if (!context.mounted) return;
    if (video != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => YoutubePlayerScreen(video: video)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load that video. Please check the URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final documents = ref.watch(pdfLibraryProvider);
    final articles = ref.watch(wikipediaLibraryProvider);
    final webArticles = ref.watch(webArticlesProvider);
    final youtubeVideos = ref.watch(youtubeProvider);
    final topics = ref.watch(readingTopicsProvider);
    final selectedTopic = ref.watch(selectedReadingTopicProvider);

    // Flatten all reading items so they can be grouped by topic.
    final items = <_LibraryItem>[
      for (final a in webArticles) _LibraryItem(a.title, 'web', a.topicId, a),
      for (final a in articles) _LibraryItem(a.title, 'wiki', a.topicId, a),
      for (final y in youtubeVideos) _LibraryItem(y.title, 'youtube', y.topicId, y),
      for (final d in documents) _LibraryItem(d.title, 'pdf', d.topicId, d),
    ];

    // Filter by selected topic (null = all topics).
    final visibleItems = selectedTopic == null
        ? items
        : items.where((i) => i.topicId == selectedTopic).toList();

    // Group visible items by topic; null = General.
    final grouped = <String?, List<_LibraryItem>>{};
    for (final item in visibleItems) {
      grouped.putIfAbsent(item.topicId, () => []).add(item);
    }

    // Order groups: General first, then topics in creation order.
    final orderedGroups = <({String? topicId, String label, List<_LibraryItem> items})>[
      if (grouped.containsKey(null))
        (topicId: null, label: 'General', items: grouped[null]!),
      for (final t in topics)
        if (grouped.containsKey(t.id))
          (topicId: t.id, label: t.name, items: grouped[t.id]!),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            leading: _MenuButton(onPressed: onMenuPressed),
            title: const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Reading Library',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            actions: [
              const GlobalSearchAction(),
              const StatsAction(),
              const ThemeToggleAction(),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (value) {
                  switch (value) {
                    case 'wikipedia':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WikipediaSearchScreen(),
                        ),
                      );
                      break;
                    case 'rss':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RssFeedListScreen(),
                        ),
                      );
                      break;
                    case 'web_article':
                      _saveWebArticle(context, ref);
                      break;
                    case 'youtube_video':
                      _saveYoutubeVideo(context, ref);
                      break;
                    case 'import_pdf':
                      _import(context, ref);
                      break;
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      break;
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'wikipedia',
                    child: ListTile(
                      leading: Icon(Icons.travel_explore_rounded),
                      title: Text('Read Wikipedia'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rss',
                    child: ListTile(
                      leading: Icon(Icons.rss_feed_rounded),
                      title: Text('RSS feeds'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'web_article',
                    child: ListTile(
                      leading: Icon(Icons.add_link_rounded),
                      title: Text('Save web article'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'youtube_video',
                    child: ListTile(
                      leading: Icon(Icons.smart_display_rounded),
                      title: Text('Save YouTube video'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import_pdf',
                    child: ListTile(
                      leading: Icon(Icons.upload_file_rounded),
                      title: Text('Import PDF'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_rounded),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          // Topic chips row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TopicChip(
                      label: 'All',
                      selected: selectedTopic == null,
                      onTap: () => ref.read(selectedReadingTopicProvider.notifier).state = null,
                    ),
                    if (grouped.containsKey(null))
                      _TopicChip(
                        label: 'General',
                        selected: selectedTopic == _generalTopicId,
                        onTap: () => ref.read(selectedReadingTopicProvider.notifier).state = _generalTopicId,
                      ),
                    for (final t in topics)
                      _TopicChip(
                        label: t.name,
                        selected: selectedTopic == t.id,
                        onTap: () => ref.read(selectedReadingTopicProvider.notifier).state = t.id,
                      ),
                    _TopicChip(
                      label: '+ New',
                      icon: Icons.add_rounded,
                      onTap: () => _createTopic(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 60),
                        const SizedBox(height: 16),
                        const Text('Your reading library is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Import a PDF and MindFlow will remember the last page you read.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(onPressed: () => _import(context, ref), icon: const Icon(Icons.upload_file_rounded), label: const Text('Import PDF')),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Nothing in this topic yet.\nLong-press any item and choose “Move to topic”.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            // Grouped lists per topic.
            for (final group in orderedGroups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    group == orderedGroups.first ? 8 : 20,
                    20,
                    8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (group.topicId != null)
                        PopupMenuButton<String>(
                          tooltip: 'Topic options',
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renameTopic(context, ref, group.topicId!, group.label);
                            } else if (value == 'delete') {
                              _deleteTopic(context, ref, group.topicId!);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit_rounded),
                                title: Text('Rename topic'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded),
                                title: Text('Delete topic'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  group == orderedGroups.last ? 96 : 0,
                ),
                sliver: SliverList.separated(
                  itemCount: group.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = group.items[index];
                    return switch (item.kind) {
                      'web' => _WebArticleCard(article: item.item as WebArticle),
                      'wiki' => _WikipediaCard(article: item.item as WikipediaArticle),
                      'youtube' => _YoutubeVideoCard(video: item.item as YoutubeVideo),
                      _ => _DocumentCard(document: item.item as PdfDocument),
                    };
                  },
                ),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _createTopic(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    String? errorText;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final input = controller.text.trim();
            if (input.isEmpty) {
              setDialogState(() => errorText = 'Enter a topic name');
              return;
            }
            Navigator.pop(dialogContext, input);
          }

          return AlertDialog(
            title: const Text('New topic'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Topic name',
                hintText: 'e.g. Deep Work, Research, Leisure',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    await waitForRouteExit();
    controller.dispose();
    if (name == null || !context.mounted) return;
    final topic = await ref.read(readingTopicsProvider.notifier).createTopic(name);
    if (context.mounted) {
      ref.read(selectedReadingTopicProvider.notifier).state = topic.id;
    }
  }

  Future<void> _renameTopic(
    BuildContext context,
    WidgetRef ref,
    String topicId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    String? errorText;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final input = controller.text.trim();
            if (input.isEmpty) {
              setDialogState(() => errorText = 'Enter a topic name');
              return;
            }
            Navigator.pop(dialogContext, input);
          }

          return AlertDialog(
            title: const Text('Rename topic'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Topic name',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    await waitForRouteExit();
    controller.dispose();
    if (name == null || !context.mounted) return;
    await ref.read(readingTopicsProvider.notifier).renameTopic(topicId, name);
  }

  Future<void> _deleteTopic(BuildContext context, WidgetRef ref, String topicId) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete topic?'),
        content: const Text('Items in this topic will move back to General.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    await waitForRouteExit();
    if (!context.mounted) return;
    await ref.read(readingTopicsProvider.notifier).deleteTopic(topicId);
    // Move orphaned items back to General.
    await ref.read(pdfLibraryProvider.notifier).clearTopic(topicId);
    await ref.read(webArticlesProvider.notifier).clearTopic(topicId);
    await ref.read(wikipediaLibraryProvider.notifier).clearTopic(topicId);
  }
}

Future<void> _showMoveToTopicMenu(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  required Object item,
}) async {
  final topics = ref.read(readingTopicsProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  String? currentTopicId = switch (kind) {
    'web' => (item as WebArticle).topicId,
    'wiki' => (item as WikipediaArticle).topicId,
    'youtube' => (item as YoutubeVideo).topicId,
    _ => (item as PdfDocument).topicId,
  };

  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Move to topic',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.folder_open_rounded),
              title: const Text('General'),
              trailing: currentTopicId == null
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(sheetContext, _generalTopicId),
            ),
            for (final topic in topics)
              ListTile(
                dense: true,
                leading: const Icon(Icons.label_rounded, color: AppColors.primary),
                title: Text(topic.name),
                trailing: currentTopicId == topic.id
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, topic.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  if (selected == null || !context.mounted) return;
  await waitForRouteExit();
  if (!context.mounted) return;
  final topicId = selected == _generalTopicId ? null : selected;

  switch (kind) {
    case 'web':
      await ref
          .read(webArticlesProvider.notifier)
          .setTopic((item as WebArticle).id, topicId);
    case 'wiki':
      await ref
          .read(wikipediaLibraryProvider.notifier)
          .setTopic(item as WikipediaArticle, topicId);
    case 'youtube':
      await ref
          .read(youtubeProvider.notifier)
          .setTopic((item as YoutubeVideo).id, topicId);
    default:
      await ref
          .read(pdfLibraryProvider.notifier)
          .setTopic((item as PdfDocument).id, topicId);
  }
}

const String _generalTopicId = '__general__';

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryItem {
  _LibraryItem(this.title, this.kind, this.topicId, this.item);

  final String title;
  final String kind;
  final String? topicId;
  final Object item;
}

class _WikipediaCard extends ConsumerWidget {
  const _WikipediaCard({required this.article});
  final WikipediaArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          leading: Container(
            width: 46,
            height: 52,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.travel_explore_rounded, color: AppColors.primary),
          ),
          title: Text(article.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('Wikipedia · Resume on page ${article.lastReadPage + 1}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WikipediaReaderScreen(article: article))),
          onLongPress: () => _showMoveToTopicMenu(
            context,
            ref,
            kind: 'wiki',
            item: article,
          ),
        ),
      );
}

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.document});
  final PdfDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists = File(document.filePath).existsSync();
    final progress = document.pageCount == null
        ? null
        : (document.lastReadPage / document.pageCount!).clamp(0.0, 1.0);
    final progressLabel = progress == null ? null : '${(progress * 100).round()}% read';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: exists
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PdfReaderScreen(document: document)),
                )
            : null,
        onLongPress: () => _showMoveToTopicMenu(
          context,
          ref,
          kind: 'pdf',
          item: document,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exists
                          ? 'Page ${document.lastReadPage}${document.pageCount == null ? '' : ' of ${document.pageCount}'}'
                          : 'PDF file is missing',
                      style: TextStyle(
                        fontSize: 12,
                        color: exists
                            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                            : AppColors.danger,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(progressLabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Remove from library',
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Remove PDF?'),
                      content: Text('Remove “${document.title}” from your reading library?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await waitForRouteExit();
                    await ref.read(pdfLibraryProvider.notifier).deleteDocument(document);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebArticleCard extends ConsumerWidget {
  const _WebArticleCard({required this.article});
  final WebArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = article.readProgress;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WebArticleScreen(article: article)),
        ),
        onLongPress: () => _showMoveToTopicMenu(
          context,
          ref,
          kind: 'web',
          item: article,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language_rounded, color: AppColors.success, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.success.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('${(progress * 100).round()}% read', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Remove from library',
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Remove Article?'),
                      content: Text('Remove "${article.title}" from your reading library?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await waitForRouteExit();
                    await ref.read(webArticlesProvider.notifier).delete(article.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YoutubeVideoCard extends ConsumerWidget {
  const _YoutubeVideoCard({required this.video});
  final YoutubeVideo video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => YoutubePlayerScreen(video: video)),
        ),
        onLongPress: () => _showMoveToTopicMenu(
          context,
          ref,
          kind: 'youtube',
          item: video,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.smart_display_rounded, color: AppColors.primary, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Remove from library',
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Remove Video?'),
                      content: Text('Remove "${video.title}" from your reading library?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await waitForRouteExit();
                    await ref.read(youtubeProvider.notifier).delete(video.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: onPressed,
    );
  }
}
