import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/reading_topic.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

/// User-defined topics that organise reading library items.
final readingTopicsProvider =
    StateNotifierProvider<ReadingTopicsNotifier, List<ReadingTopic>>((ref) {
  return ReadingTopicsNotifier(ref.watch(storageServiceProvider));
});

class ReadingTopicsNotifier extends StateNotifier<List<ReadingTopic>> {
  ReadingTopicsNotifier(this._storage) : super([]) {
    state = _storage.loadReadingTopics();
  }

  final StorageService _storage;

  Future<ReadingTopic> createTopic(String name) async {
    final topic = ReadingTopic(
      id: const Uuid().v4(),
      name: name.trim().isEmpty ? 'Topic' : name.trim(),
      colorIndex: state.length % 8,
    );
    final updated = [...state, topic];
    await _storage.saveReadingTopics(updated);
    state = updated;
    return topic;
  }

  Future<void> renameTopic(String id, String name) async {
    final updated = [
      for (final t in state)
        if (t.id == id) t.copyWith(name: name.trim().isEmpty ? 'Topic' : name.trim()) else t,
    ];
    await _storage.saveReadingTopics(updated);
    state = updated;
  }

  Future<void> deleteTopic(String id) async {
    final updated = state.where((t) => t.id != id).toList();
    await _storage.saveReadingTopics(updated);
    state = updated;
  }
}