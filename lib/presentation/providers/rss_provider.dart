import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/rss_feed.dart';
import '../../core/services/rss_service.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

final rssServiceProvider = Provider<RssService>((ref) => RssService());

final rssFeedsProvider = StateNotifierProvider<RssFeedsNotifier, List<RssFeed>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final service = ref.watch(rssServiceProvider);
  return RssFeedsNotifier(storage, service);
});

class RssFeedsNotifier extends StateNotifier<List<RssFeed>> {
  final StorageService _storage;
  final RssService _service;

  RssFeedsNotifier(this._storage, this._service) : super(_storage.loadRssFeeds());

  Future<bool> _persist(List<RssFeed> next) async {
    state = next;
    return _storage.saveRssFeeds(next);
  }

  Future<RssFeed?> addFeed(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (state.any((f) => f.url == trimmed)) {
      return state.firstWhere((f) => f.url == trimmed);
    }

    final fetched = await _service.fetchFeed(trimmed);
    final updated = [fetched, ...state];
    await _persist(updated);
    return fetched;
  }

  Future<void> refreshFeed(String id) async {
    final index = state.indexWhere((f) => f.id == id);
    if (index < 0) return;
    final existing = state[index];
    try {
      final fetched = await _service.fetchFeed(existing.url);
      final refreshed = existing.copyWith(
        title: fetched.title,
        lastRefreshedAt: DateTime.now(),
        error: null,
        items: fetched.items,
      );
      final updated = List<RssFeed>.from(state);
      updated[index] = refreshed;
      await _persist(updated);
    } catch (e) {
      final updated = List<RssFeed>.from(state);
      updated[index] = existing.copyWith(error: e.toString());
      await _persist(updated);
    }
  }

  Future<void> removeFeed(String id) async {
    await _persist(state.where((f) => f.id != id).toList());
  }
}