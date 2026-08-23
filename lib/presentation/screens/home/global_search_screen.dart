import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notes_provider.dart';
import '../../providers/pdf_library_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/wikipedia_provider.dart';
import '../library/pdf_reader_screen.dart';
import '../library/wikipedia_reader_screen.dart';
import '../notes/note_editor_screen.dart';
import '../reminders/add_edit_reminder_sheet.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String value) => value.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider).where((item) => _matches('${item.title} ${item.description}')).toList();
    final notes = ref.watch(notesProvider).where((item) => _matches('${item.title} ${item.content} ${item.tags.join(' ')}')).toList();
    final documents = ref.watch(pdfLibraryProvider).where((item) => _matches(item.title)).toList();
    final articles = ref.watch(wikipediaLibraryProvider).where((item) => _matches(item.title)).toList();
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search MindFlow')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Notes, reminders, PDFs, articles…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasQuery ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _controller.clear(); setState(() => _query = ''); }) : null,
              ),
            ),
          ),
          Expanded(
            child: !hasQuery
                ? const Center(child: Text('Search everything in your MindFlow library.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      _SearchGroup(
                        title: 'Reminders',
                        icon: Icons.alarm_rounded,
                        count: reminders.length,
                        children: [
                          for (final reminder in reminders)
                            ListTile(
                              title: Text(reminder.title),
                              subtitle: Text(reminder.description.isEmpty ? 'Reminder' : reminder.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () => AddEditReminderSheet.show(context, reminder: reminder),
                            ),
                        ],
                      ),
                      _SearchGroup(
                        title: 'Notes',
                        icon: Icons.edit_note_rounded,
                        count: notes.length,
                        children: [
                          for (final note in notes)
                            ListTile(
                              title: Text(note.title),
                              subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: note, isChecklistMode: note.isChecklist))),
                            ),
                        ],
                      ),
                      _SearchGroup(
                        title: 'PDFs',
                        icon: Icons.picture_as_pdf_rounded,
                        count: documents.length,
                        children: [
                          for (final document in documents)
                            ListTile(title: Text(document.title), subtitle: Text('Resume on page ${document.lastReadPage}'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfReaderScreen(document: document)))),
                        ],
                      ),
                      _SearchGroup(
                        title: 'Wikipedia reads',
                        icon: Icons.travel_explore_rounded,
                        count: articles.length,
                        children: [
                          for (final article in articles)
                            ListTile(title: Text(article.title), subtitle: Text('Resume on page ${article.lastReadPage + 1}'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WikipediaReaderScreen(article: article)))),
                        ],
                      ),
                      if (reminders.isEmpty && notes.isEmpty && documents.isEmpty && articles.isEmpty)
                        const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('No matches found.'))),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchGroup extends StatelessWidget {
  const _SearchGroup({required this.title, required this.icon, required this.count, required this.children});
  final String title;
  final IconData icon;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          children: [
            ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: Text('$count')),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}
