import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/note.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

// Search Query for Notes
final notesSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected Filter Tag for Notes (null = All)
final selectedNotesTagProvider = StateProvider<String?>((ref) => null);

// Selected Folder for Notes (null = All Folders)
final selectedNotesFolderProvider = StateProvider<String?>((ref) => null);

// Notes StateNotifier Provider
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return NotesNotifier(storage);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final StorageService _storage;

  NotesNotifier(this._storage) : super([]) {
    _load();
  }

  void _load() {
    state = _storage.loadNotes();
  }

  Future<void> addNote(Note note) async {
    state = [note, ...state];
    await _storage.saveNotes(state);
  }

  Future<void> updateNote(Note updatedNote) async {
    state = [
      for (final note in state)
        if (note.id == updatedNote.id)
          updatedNote.copyWith(updatedAt: DateTime.now())
        else
          note
    ];
    await _storage.saveNotes(state);
  }

  Future<void> deleteNote(String id) async {
    state = state.where((note) => note.id != id).toList();
    await _storage.saveNotes(state);
  }

  Future<void> togglePin(String id) async {
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            isPinned: !note.isPinned,
            updatedAt: DateTime.now(),
          )
        else
          note
    ];
    await _storage.saveNotes(state);
  }

  Future<void> toggleArchive(String id) async {
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            isArchived: !note.isArchived,
            updatedAt: DateTime.now(),
          )
        else
          note
    ];
    await _storage.saveNotes(state);
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    state = [
      for (final note in state)
        if (note.id == noteId)
          note.copyWith(
            checklistItems: [
              for (final item in note.checklistItems)
                if (item.id == itemId)
                  item.copyWith(isChecked: !item.isChecked)
                else
                  item
            ],
            updatedAt: DateTime.now(),
          )
        else
          note
    ];
    await _storage.saveNotes(state);
  }

  Note? getNoteById(String id) {
    try {
      return state.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Filtered Notes Provider
final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider);
  final searchQuery = ref.watch(notesSearchQueryProvider).trim().toLowerCase();
  final selectedTag = ref.watch(selectedNotesTagProvider);
  final selectedFolder = ref.watch(selectedNotesFolderProvider);

  var result = notes.where((note) => !note.isArchived).toList();

  if (selectedFolder != null) {
    result = result.where((note) => note.folder == selectedFolder).toList();
  }

  if (selectedTag != null && selectedTag.isNotEmpty) {
    result = result.where((note) => note.tags.contains(selectedTag)).toList();
  }

  if (searchQuery.isNotEmpty) {
    result = result.where((note) {
      final titleMatch = note.title.toLowerCase().contains(searchQuery);
      final contentMatch = note.content.toLowerCase().contains(searchQuery);
      final tagMatch = note.tags.any((t) => t.toLowerCase().contains(searchQuery));
      final checklistMatch = note.checklistItems.any(
        (item) => item.text.toLowerCase().contains(searchQuery),
      );
      return titleMatch || contentMatch || tagMatch || checklistMatch;
    }).toList();
  }

  // Sort: Pinned first, then by updatedAt descending
  result.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return b.updatedAt.compareTo(a.updatedAt);
  });

  return result;
});

// All Available Tags Provider
final allNotesTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesProvider);
  final Set<String> tags = {};
  for (final note in notes) {
    tags.addAll(note.tags);
  }
  return tags.toList()..sort();
});

// All Available Folders Provider
final allNotesFoldersProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesProvider);
  final Set<String> folders = {};
  for (final note in notes) {
    if (note.folder != null && note.folder!.isNotEmpty) {
      folders.add(note.folder!);
    }
  }
  return folders.toList()..sort();
});
