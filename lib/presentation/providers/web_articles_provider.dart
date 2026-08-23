import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/web_article.dart';
import '../../core/services/article_extraction_service.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';
import 'package:uuid/uuid.dart';

final articleExtractionServiceProvider = Provider<ArticleExtractionService>(
  (_) => ArticleExtractionService(),
);

final webArticlesProvider =
    StateNotifierProvider<WebArticlesNotifier, List<WebArticle>>((ref) {
  return WebArticlesNotifier(ref.watch(storageServiceProvider));
});

class WebArticlesNotifier extends StateNotifier<List<WebArticle>> {
  WebArticlesNotifier(this._storage) : super([]) {
    state = _storage.loadWebArticles();
  }

  final StorageService _storage;

  Future<WebArticle?> fetchAndSave(String url, ArticleExtractionService extractor) async {
    try {
      final result = await extractor.extract(url);
      final article = WebArticle(
        id: const Uuid().v4(),
        url: url,
        title: result.title,
        author: result.author,
        extractedContent: result.content,
        savedAt: DateTime.now(),
      );
      final updated = [article, ...state];
      await _storage.saveWebArticles(updated);
      state = updated;
      return article;
    } catch (e) {
      debugPrint('WebArticlesNotifier.fetchAndSave error: $e');
      return null;
    }
  }

  Future<void> updateProgress(String id, double progress) async {
    final updated = [
      for (final a in state) if (a.id == id) a.copyWith(readProgress: progress) else a,
    ];
    await _storage.saveWebArticles(updated);
    state = updated;
  }

  Future<void> setLinkedNote(String id, String? noteId) async {
    final updated = [
      for (final a in state)
        if (a.id == id) a.copyWith(linkedNoteId: noteId) else a,
    ];
    await _storage.saveWebArticles(updated);
    state = updated;
  }

  Future<void> setTopic(String id, String? topicId) async {
    final updated = [
      for (final a in state)
        if (a.id == id) a.copyWith(topicId: topicId) else a,
    ];
    await _storage.saveWebArticles(updated);
    state = updated;
  }

  Future<void> clearTopic(String topicId) async {
    final updated = [
      for (final a in state)
        if (a.topicId == topicId) a.copyWith(topicId: null) else a,
    ];
    await _storage.saveWebArticles(updated);
    state = updated;
  }

  Future<void> delete(String id) async {
    final updated = state.where((a) => a.id != id).toList();
    await _storage.saveWebArticles(updated);
    state = updated;
  }
}
