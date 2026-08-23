import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/pdf_annotation.dart';
import '../../core/models/pdf_document.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

final pdfLibraryProvider =
    StateNotifierProvider<PdfLibraryNotifier, List<PdfDocument>>((ref) {
  return PdfLibraryNotifier(ref.watch(storageServiceProvider));
});

class PdfLibraryNotifier extends StateNotifier<List<PdfDocument>> {
  PdfLibraryNotifier(this._storage) : super([]) {
    state = _storage.loadPdfDocuments();
  }

  final StorageService _storage;

  Future<PdfDocument?> importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final pickedFile = result?.files.single;
    if (pickedFile == null || pickedFile.path == null) return null;

    final libraryDirectory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${libraryDirectory.path}${Platform.pathSeparator}pdf_library');
    if (!await pdfDirectory.exists()) await pdfDirectory.create(recursive: true);

    final id = const Uuid().v4();
    final source = File(pickedFile.path!);
    final extension = pickedFile.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'pdf';
    final savedFile = await source.copy('${pdfDirectory.path}${Platform.pathSeparator}$id.$extension');
    final now = DateTime.now();
    final document = PdfDocument(
      id: id,
      title: pickedFile.name.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), ''),
      filePath: savedFile.path,
      addedAt: now,
      lastOpenedAt: now,
    );

    final updatedState = [document, ...state];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save this PDF to the library.');
    }
    state = updatedState;
    return document;
  }

  Future<void> saveReadingProgress(
    String id, {
    required int page,
    int? pageCount,
  }) async {
    final updatedState = [
      for (final document in state)
        if (document.id == id)
          document.copyWith(
            lastReadPage: page,
            pageCount: pageCount,
            lastOpenedAt: DateTime.now(),
          )
        else
          document,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save reading progress.');
    }
    state = updatedState;
  }

  Future<void> deleteDocument(PdfDocument document) async {
    final updatedState = state.where((item) => item.id != document.id).toList();
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not remove this PDF from the library.');
    }
    state = updatedState;
    final file = File(document.filePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> toggleBookmark(String docId, int page) async {
    final updatedState = [
      for (final doc in state)
        if (doc.id == docId)
          doc.copyWith(
            bookmarks: doc.bookmarks.contains(page)
                ? (List<int>.from(doc.bookmarks)..remove(page))
                : ([...doc.bookmarks, page]..sort()),
          )
        else
          doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save bookmark.');
    }
    state = updatedState;
  }

  Future<void> updateBookmarks(String docId, List<int> bookmarks) async {
    final updatedState = [
      for (final doc in state)
        if (doc.id == docId) doc.copyWith(bookmarks: bookmarks..sort()) else doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save bookmarks.');
    }
    state = updatedState;
  }

  Future<void> setLinkedNote(String docId, String? noteId) async {
    final updatedState = [
      for (final doc in state)
        if (doc.id == docId) doc.copyWith(linkedNoteId: noteId) else doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save linked note.');
    }
    state = updatedState;
  }

  Future<void> setTopic(String docId, String? topicId) async {
    final updatedState = [
      for (final doc in state)
        if (doc.id == docId) doc.copyWith(topicId: topicId) else doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save topic.');
    }
    state = updatedState;
  }

  Future<void> clearTopic(String topicId) async {
    final updatedState = [
      for (final doc in state)
        if (doc.topicId == topicId) doc.copyWith(topicId: null) else doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not clear topic.');
    }
    state = updatedState;
  }

  Future<void> updateAnnotations(
    String docId,
    List<PdfAnnotation> annotations,
  ) async {
    final updatedState = [
      for (final doc in state)
        if (doc.id == docId) doc.copyWith(annotations: annotations) else doc,
    ];
    if (!await _storage.savePdfDocuments(updatedState)) {
      throw StateError('Could not save annotations.');
    }
    state = updatedState;
  }
}
