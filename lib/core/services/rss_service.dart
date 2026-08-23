import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/rss_feed.dart';

/// Fetches and parses RSS 2.0 feeds using the lightweight `xml` package
/// (chosen over `webfeed` because that package pins an old `intl`).
class RssService {
  final http.Client _client;

  RssService({http.Client? client}) : _client = client ?? http.Client();

  Future<RssFeed> fetchFeed(String url) async {
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Feed returned HTTP ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final channel = document.findAllElements('channel').firstOrNull ??
        document.findAllElements('feed').firstOrNull;
    if (channel == null) {
      throw Exception('No RSS channel found in feed');
    }

    final title = _textOf(channel, 'title') ?? url;

    final items = <RssItem>[];
    final entries = channel.findAllElements('item');
    for (final entry in entries.take(50)) {
      final link = _textOf(entry, 'link') ?? _linkFromAtom(entry);
      items.add(
        RssItem(
          id: _textOf(entry, 'guid') ?? link ?? '',
          title: _textOf(entry, 'title') ?? 'Untitled',
          link: link ?? '',
          description: _textOf(entry, 'description') ?? '',
          publishedAt: _parseDate(
            _textOf(entry, 'pubDate') ?? _textOf(entry, 'published'),
          ),
        ),
      );
    }

    return RssFeed(
      id: url,
      title: title,
      url: url,
      addedAt: DateTime.now(),
      lastRefreshedAt: DateTime.now(),
      items: items,
    );
  }

  String? _textOf(XmlElement parent, String tag) {
    for (final child in parent.childElements) {
      if (child.name.local == tag) {
        final text = child.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  String? _linkFromAtom(XmlElement entry) {
    for (final child in entry.childElements) {
      if (child.name.local == 'link') {
        final href = child.getAttribute('href');
        if (href != null && href.isNotEmpty) return href;
      }
    }
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  void dispose() {
    _client.close();
  }
}