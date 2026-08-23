import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/wikipedia_article.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/wikipedia_service.dart';
import 'app_providers.dart';

final wikipediaServiceProvider = Provider<WikipediaService>((ref) => WikipediaService());

final wikipediaLibraryProvider =
    StateNotifierProvider<WikipediaLibraryNotifier, List<WikipediaArticle>>((ref) {
  return WikipediaLibraryNotifier(ref.watch(storageServiceProvider));
});

class WikipediaLibraryNotifier extends StateNotifier<List<WikipediaArticle>> {
  WikipediaLibraryNotifier(this._storage) : super(_storage.loadWikipediaArticles());
  final StorageService _storage;

  Future<void> saveArticle(WikipediaArticle article) async {
    final updated = [
      article,
      for (final existing in state)
        if (existing.title != article.title) existing,
    ];
    final capped = updated.take(12).toList(growable: false);
    if (!await _storage.saveWikipediaArticles(capped)) {
      throw StateError('Could not save this article for later reading.');
    }
    state = capped;
  }

  Future<void> saveProgress(WikipediaArticle article, int page) {
    return saveArticle(article.copyWith(lastReadPage: page, lastOpenedAt: DateTime.now()));
  }

  Future<void> setLinkedNote(WikipediaArticle article, String? noteId) {
    return saveArticle(article.copyWith(linkedNoteId: noteId));
  }

  Future<void> setTopic(WikipediaArticle article, String? topicId) {
    return saveArticle(article.copyWith(topicId: topicId));
  }

  Future<void> clearTopic(String topicId) async {
    final updated = [
      for (final a in state)
        if (a.topicId == topicId) a.copyWith(topicId: null) else a,
    ];
    if (!await _storage.saveWikipediaArticles(updated)) {
      throw StateError('Could not clear topic.');
    }
    state = updated;
  }
}
