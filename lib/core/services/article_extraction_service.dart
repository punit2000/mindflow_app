import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// Fetches a URL and extracts clean readable article content.
class ArticleExtractionService {
  static const _timeout = Duration(seconds: 15);

  Future<({String title, String? author, String content})> extract(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (compatible; MindFlow/1.0; +https://mindflow.app)',
        'Accept': 'text/html,application/xhtml+xml',
      }).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Could not load URL (status ${response.statusCode})');
      }

      final document = html_parser.parse(response.body);

      final title = _extractTitle(document);
      final author = _extractAuthor(document);
      final content = _extractContent(document);

      return (title: title, author: author, content: content);
    } catch (e) {
      debugPrint('ArticleExtractionService error: $e');
      rethrow;
    }
  }

  String _extractTitle(html_dom.Document document) {
    // Try og:title, then <title>, then first h1
    final ogTitle = document.querySelector('meta[property="og:title"]')?.attributes['content'];
    if (ogTitle != null && ogTitle.isNotEmpty) return ogTitle.trim();

    final metaTitle = document.querySelector('meta[name="title"]')?.attributes['content'];
    if (metaTitle != null && metaTitle.isNotEmpty) return metaTitle.trim();

    final title = document.querySelector('title')?.text;
    if (title != null && title.isNotEmpty) return title.trim();

    final h1 = document.querySelector('h1')?.text;
    return h1?.trim() ?? 'Untitled Article';
  }

  String? _extractAuthor(html_dom.Document document) {
    final selectors = [
      'meta[name="author"]',
      'meta[property="article:author"]',
      '[rel="author"]',
      '.author',
      '.byline',
    ];
    for (final selector in selectors) {
      final el = document.querySelector(selector);
      if (el != null) {
        final val = el.attributes['content'] ?? el.text;
        if (val.trim().isNotEmpty) return val.trim();
      }
    }
    return null;
  }

  String _extractContent(html_dom.Document document) {
    // Remove noise elements
    for (final selector in [
      'script', 'style', 'nav', 'footer', 'header', 'aside',
      '.ad', '.ads', '.advertisement', '.social', '.share',
      '.comments', '.sidebar', '.related', '[role="navigation"]',
      '[role="banner"]', '[role="complementary"]',
    ]) {
      document.querySelectorAll(selector).forEach((el) => el.remove());
    }

    // Try article/main content containers first
    final contentSelectors = [
      'article',
      '[role="main"]',
      'main',
      '.article-body',
      '.article-content',
      '.post-content',
      '.entry-content',
      '.content-body',
      '#content',
      '#article',
    ];

    html_dom.Element? container;
    for (final sel in contentSelectors) {
      container = document.querySelector(sel);
      if (container != null) break;
    }

    container ??= document.body;
    if (container == null) return '';

    return _nodeToText(container).trim();
  }

  String _nodeToText(html_dom.Element element) {
    final buffer = StringBuffer();

    for (final child in element.nodes) {
      if (child is html_dom.Text) {
        final text = child.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.trim().isNotEmpty) buffer.write(text);
      } else if (child is html_dom.Element) {
        final tag = child.localName?.toLowerCase() ?? '';
        final isBlock = const {
          'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
          'li', 'blockquote', 'pre', 'br', 'tr',
        }.contains(tag);

        if (isBlock) buffer.write('\n');

        // Add markdown-like headings
        if (['h1', 'h2', 'h3'].contains(tag)) {
          buffer.write('\n## ');
        } else if (['h4', 'h5', 'h6'].contains(tag)) {
          buffer.write('\n### ');
        }

        buffer.write(_nodeToText(child));

        if (isBlock) buffer.write('\n');
      }
    }

    // Collapse multiple blank lines
    return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
