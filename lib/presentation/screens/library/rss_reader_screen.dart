import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/models/rss_feed.dart';
import '../../../core/theme/app_colors.dart';

class RssReaderScreen extends ConsumerStatefulWidget {
  const RssReaderScreen({super.key, required this.feed});

  final RssFeed feed;

  @override
  ConsumerState<RssReaderScreen> createState() => _RssReaderScreenState();
}

class _RssReaderScreenState extends ConsumerState<RssReaderScreen> {
  int _currentIndex = 0;
  RssItem get _item => widget.feed.items[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = widget.feed;

    return Scaffold(
      appBar: AppBar(
        title: Text(feed.title),
        centerTitle: true,
      ),
      body: feed.items.isEmpty
          ? Center(
              child: Text(
                feed.error == null ? 'No articles in this feed yet.' : 'Could not refresh feed.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            )
          : Column(
              children: [
                // Article selector
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: feed.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = feed.items[index];
                      final selected = index == _currentIndex;
                      return ChoiceChip(
                        label: Text(
                          item.title.isEmpty ? 'Untitled' : item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() => _currentIndex = index),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _RssArticleView(item: _item)),
              ],
            ),
    );
  }
}

class _RssArticleView extends StatelessWidget {
  const _RssArticleView({required this.item});

  final RssItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            item.title.isEmpty ? 'Untitled' : item.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            item.publishedAt == null
                ? 'No date'
                : DateFormat('EEEE, MMM d, yyyy · h:mm a').format(item.publishedAt!),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: item.description.isEmpty
              ? Center(
                  child: Text(
                    'This article has no content preview. Tap “Open in browser” if the source link is available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadHtmlString(
                      _htmlDocument(),
                      baseUrl: item.link.isNotEmpty ? item.link : null,
                    ),
                ),
        ),
      ],
    );
  }

  String _htmlDocument() {
    final baseStyle = '''
      body { font-family: -apple-system, 'Segoe UI', sans-serif; line-height: 1.55; padding: 16px; }
      img { max-width: 100%; height: auto; }
      pre { white-space: pre-wrap; word-wrap: break-word; }
    ''';
    final meta = item.link.isEmpty
        ? ''
        : '<p style="font-size:12px"><a href="${item.link}">Open in browser</a></p>';
    return '''
      <!DOCTYPE html>
      <html><head><meta name="viewport" content="width=device-width, initial-scale=1">
      <style>$baseStyle</style></head>
      <body>$meta
      <div>${item.description}</div>
      </body></html>
    ''';
  }
}