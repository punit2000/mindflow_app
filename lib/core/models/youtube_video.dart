class YoutubeVideo {
  final String id;
  final String videoId;
  final String url;
  final String title;
  final String author;
  final String thumbnailUrl;
  final DateTime savedAt;
  final Duration progress;
  final String? topicId;

  const YoutubeVideo({
    required this.id,
    required this.videoId,
    required this.url,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.savedAt,
    this.progress = Duration.zero,
    this.topicId,
  });

  YoutubeVideo copyWith({
    Duration? progress,
    Object? topicId = _sentinel,
  }) {
    return YoutubeVideo(
      id: id,
      videoId: videoId,
      url: url,
      title: title,
      author: author,
      thumbnailUrl: thumbnailUrl,
      savedAt: savedAt,
      progress: progress ?? this.progress,
      topicId: topicId == _sentinel ? this.topicId : topicId as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoId': videoId,
        'url': url,
        'title': title,
        'author': author,
        'thumbnailUrl': thumbnailUrl,
        'savedAt': savedAt.toIso8601String(),
        'progressSeconds': progress.inSeconds,
        'topicId': topicId,
      };

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) => YoutubeVideo(
        id: json['id'] as String,
        videoId: json['videoId'] as String,
        url: json['url'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
        progress: Duration(seconds: (json['progressSeconds'] as num?)?.toInt() ?? 0),
        topicId: json['topicId'] as String?,
      );
}
