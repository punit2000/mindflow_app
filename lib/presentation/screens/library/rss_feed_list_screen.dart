import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/rss_feed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/rss_provider.dart';
import 'rss_reader_screen.dart';

class RssFeedListScreen extends ConsumerWidget {
  const RssFeedListScreen({super.key});

  Future<void> _addFeed(BuildContext context, WidgetRef ref) async {
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
            title: const Text('Add RSS feed'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Feed URL',
                hintText: 'https://example.com/feed.xml',
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
                child: const Text('Subscribe'),
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
      const SnackBar(content: Text('Fetching feed…')),
    );
    try {
      final feed = await ref.read(rssFeedsProvider.notifier).addFeed(url);
      if (!context.mounted) return;
      if (feed != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RssReaderScreen(feed: feed)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load that feed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feeds = ref.watch(rssFeedsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS Feeds'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFeed(context, ref),
        icon: const Icon(Icons.rss_feed_rounded),
        label: const Text('Add Feed'),
      ),
      body: feeds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rss_feed_rounded,
                        size: 54,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subscribe to feeds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add a blog or news RSS feed and read the latest articles offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                for (final feed in feeds) {
                  await ref.read(rssFeedsProvider.notifier).refreshFeed(feed.id);
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: feeds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final feed = feeds[index];
                  return _FeedCard(feed: feed);
                },
              ),
            ),
    );
  }
}

class _FeedCard extends ConsumerWidget {
  const _FeedCard({required this.feed});

  final RssFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RssReaderScreen(feed: feed)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rss_feed_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${feed.items.length} articles'
                      '${feed.error != null ? ' · error refreshing' : ''}'
                      '${feed.lastRefreshedAt != null ? ' · ${DateFormat('MMM d').format(feed.lastRefreshedAt!)}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: feed.error != null
                            ? AppColors.danger
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.read(rssFeedsProvider.notifier).refreshFeed(feed.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Unsubscribe',
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Unsubscribe?'),
                      content: Text('Remove “${feed.title}”?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await waitForRouteExit();
                    await ref.read(rssFeedsProvider.notifier).removeFeed(feed.id);
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