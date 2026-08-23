import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/models/youtube_video.dart';
import '../../core/services/storage_service.dart';
import 'app_providers.dart';

final youtubeProvider = StateNotifierProvider<YoutubeNotifier, List<YoutubeVideo>>((ref) {
  return YoutubeNotifier(ref.watch(storageServiceProvider));
});

class YoutubeNotifier extends StateNotifier<List<YoutubeVideo>> {
  YoutubeNotifier(this._storage) : super([]) {
    state = _storage.loadYoutubeVideos();
  }

  final StorageService _storage;

  Future<YoutubeVideo?> fetchAndSave(String url) async {
    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(url);
      
      final youtubeVideo = YoutubeVideo(
        id: const Uuid().v4(),
        videoId: video.id.value,
        url: url,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        savedAt: DateTime.now(),
      );

      final updated = [youtubeVideo, ...state];
      await _storage.saveYoutubeVideos(updated);
      state = updated;
      
      yt.close();
      return youtubeVideo;
    } catch (e) {
      debugPrint('YoutubeNotifier.fetchAndSave error: $e');
      return null;
    }
  }

  Future<void> updateProgress(String id, Duration progress) async {
    final updated = [
      for (final v in state) if (v.id == id) v.copyWith(progress: progress) else v,
    ];
    await _storage.saveYoutubeVideos(updated);
    state = updated;
  }

  Future<void> setTopic(String id, String? topicId) async {
    final updated = [
      for (final v in state)
        if (v.id == id) v.copyWith(topicId: topicId) else v,
    ];
    await _storage.saveYoutubeVideos(updated);
    state = updated;
  }

  Future<void> clearTopic(String topicId) async {
    final updated = [
      for (final v in state)
        if (v.topicId == topicId) v.copyWith(topicId: null) else v,
    ];
    await _storage.saveYoutubeVideos(updated);
    state = updated;
  }

  Future<void> delete(String id) async {
    final updated = state.where((v) => v.id != id).toList();
    await _storage.saveYoutubeVideos(updated);
    state = updated;
  }
}
