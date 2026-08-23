import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/note.dart';
import '../../core/services/wiki_link_parser.dart';
import 'notes_provider.dart';

/// Maps a normalized note title to the note with that title.
///
/// Titles are compared case-insensitively. When several notes share a title
/// the most recently updated note wins, which is the same behaviour used when
/// navigating a `[[wiki link]]`.
final noteTitleIndexProvider = Provider<Map<String, Note>>((ref) {
  final notes = ref.watch(notesProvider);
  final index = <String, Note>{};
  for (final note in notes) {
    index[note.title.trim().toLowerCase()] = note;
  }
  return index;
});

/// Backlinks index: for each note id, the list of notes that reference it via
/// `[[Note Title]]` syntax in their content.
final noteBacklinksProvider = Provider<Map<String, List<Note>>>((ref) {
  final notes = ref.watch(notesProvider);
  final index = <String, List<Note>>{};
  for (final note in notes) {
    for (final title in WikiLinkParser.parseTitles(note.content)) {
      final matches = notes.where(
        (n) => n.title.trim().toLowerCase() == title.toLowerCase(),
      );
      for (final match in matches) {
        index.putIfAbsent(match.id, () => []).add(note);
      }
    }
  }
  return index;
});

/// Resolves a raw `[[Title]]` string to a [Note] if one exists.
Note? resolveWikiLink(String rawTitle, Map<String, Note> index) {
  if (rawTitle.isEmpty) return null;
  return index[rawTitle.trim().toLowerCase()];
}