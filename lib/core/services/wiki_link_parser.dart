/// Parses and renders Obsidian-style `[[Note Title]]` wiki links.
///
/// The syntax is used in note content to reference other notes by title.
/// Rendering converts each link into a standard markdown link with a custom
/// `note://` scheme so it can be rendered by [MarkdownBody] and intercepted in
/// its `onTapLink` callback.
class WikiLinkParser {
  static final RegExp _pattern = RegExp(r'\[\[([^\]]+)\]\]');
  static const String _scheme = 'note://';

  /// Extracts the titles referenced by `[[...]]` syntax in [content].
  static List<String> parseTitles(String content) {
    if (content.isEmpty) return const [];
    return _pattern
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Converts `[[Title]]` into `[Title](note://<encoded>)` markdown links.
  static String render(String content) {
    if (content.isEmpty) return content;
    return content.replaceAllMapped(_pattern, (m) {
      final title = m.group(1)!.trim();
      final encoded = Uri.encodeComponent(title);
      return '[$title]($_scheme$encoded)';
    });
  }

  /// Returns the decoded note title if [href] is a `note://` link.
  static String? decodeHref(String href) {
    if (!href.startsWith(_scheme)) return null;
    return Uri.decodeComponent(href.substring(_scheme.length));
  }
}