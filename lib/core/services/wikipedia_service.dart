import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wikipedia_article.dart';

class WikipediaSearchResult {
  const WikipediaSearchResult({required this.title, required this.description});
  final String title;
  final String description;
}

class WikipediaService {
  static const _host = 'en.wikipedia.org';
  final http.Client _client;

  WikipediaService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<WikipediaSearchResult>> search(String query) async {
    final response = await _get({
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'srlimit': '15',
      'format': 'json',
      'formatversion': '2',
      'origin': '*',
    });
    final items = ((response['query'] as Map<String, dynamic>?)?['search'] as List?) ?? [];
    return items.map((item) {
      final result = item as Map<String, dynamic>;
      return WikipediaSearchResult(
        title: result['title'] as String? ?? 'Untitled article',
        description: _plainText(result['snippet'] as String? ?? ''),
      );
    }).toList();
  }

  Future<List<String>> autocomplete(String query) async {
    if (query.trim().length < 2) return const [];
    final response = await _get({
      'action': 'query',
      'list': 'prefixsearch',
      'pssearch': query.trim(),
      'pslimit': '7',
      'format': 'json',
      'formatversion': '2',
      'origin': '*',
    });
    final items = ((response['query'] as Map<String, dynamic>?)?['prefixsearch'] as List?) ?? [];
    return items
        .map((item) => (item as Map<String, dynamic>)['title'] as String? ?? '')
        .where((title) => title.isNotEmpty)
        .toList();
  }

  Future<WikipediaArticle> loadArticle(String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    final uri = Uri.parse('https://$_host/w/rest.php/v1/page/$encodedTitle/html');
    final response = await _client
        .get(uri, headers: const {'Api-User-Agent': 'MindFlow/1.2 Wikipedia reader'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) {
      throw StateError('Wikipedia article was not found.');
    }
    if (response.statusCode != 200) {
      throw StateError('Wikipedia request failed (${response.statusCode}).');
    }
    final content = _articleText(response.body).trim();
    if (content.isEmpty) throw StateError('Wikipedia has no readable text for this page.');
    return WikipediaArticle(
      title: title,
      content: content,
      lastReadPage: 0,
      lastOpenedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _get(Map<String, String> parameters) async {
    final uri = Uri.https(_host, '/w/api.php', parameters);
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Wikipedia request failed (${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _plainText(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'");

  String _articleText(String html) {
    var text = html;
    for (final tag in ['script', 'style', 'table', 'figure', 'sup', 'math']) {
      text = text.replaceAll(
        RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
        '',
      );
    }
    return _plainText(
      text
          .replaceAll(RegExp(r'<br\\s*/?>', caseSensitive: false), '\n')
          .replaceAll(
            RegExp(r'<h[1-6][^>]*>', caseSensitive: false),
            '\n\n## ',
          )
          .replaceAll(
            RegExp(r'</h[1-6]>', caseSensitive: false),
            '\n\n',
          )
          .replaceAll(
            RegExp(r'</?(?:p|div|section|li|blockquote)[^>]*>', caseSensitive: false),
            '\n\n',
          )
          .replaceAll('&nbsp;', ' '),
    ).replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
