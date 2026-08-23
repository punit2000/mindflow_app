import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/wiki_link_parser.dart';
import '../providers/note_links_provider.dart';
import '../screens/notes/note_editor_screen.dart';

/// Renders [data] as markdown with `[[wiki links]]` resolved to other notes.
///
/// Tapping a wiki link opens the target note in the editor.
class WikiLinkedMarkdown extends ConsumerWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final bool softLineBreak;
  final bool selectable;

  const WikiLinkedMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
    this.softLineBreak = false,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleIndex = ref.watch(noteTitleIndexProvider);
    final rendered = WikiLinkParser.render(data);

    return MarkdownBody(
      data: rendered,
      softLineBreak: softLineBreak,
      selectable: selectable,
      styleSheet: styleSheet,
      onTapLink: (text, href, title) {
        final targetTitle = WikiLinkParser.decodeHref(href ?? '');
        final note = targetTitle == null
            ? null
            : resolveWikiLink(targetTitle, titleIndex);
        if (note == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No note titled “$text”')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: note)),
        );
      },
    );
  }
}