import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/models/youtube_video.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/youtube_provider.dart';

class YoutubePlayerScreen extends ConsumerStatefulWidget {
  const YoutubePlayerScreen({super.key, required this.video});
  
  final YoutubeVideo video;

  @override
  ConsumerState<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends ConsumerState<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoId,
      autoPlay: true,
      startSeconds: widget.video.progress.inSeconds.toDouble(),
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    // Periodically save progress
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    try {
      final position = await _controller.currentTime;
      if (mounted) {
        ref.read(youtubeProvider.notifier).updateProgress(
              widget.video.id,
              Duration(seconds: position.toInt()),
            );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.author,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
