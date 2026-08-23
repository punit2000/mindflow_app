class WebArticle {
  final String id;
  final String url;
  final String title;
  final String? author;
  final String extractedContent;
  final DateTime savedAt;
  final double readProgress; // 0.0 - 1.0
  final String? linkedNoteId;
  final String? topicId;

  const WebArticle({
    required this.id,
    required this.url,
    required this.title,
    this.author,
    required this.extractedContent,
    required this.savedAt,
    this.readProgress = 0.0,
    this.linkedNoteId,
    this.topicId,
  });

  WebArticle copyWith({
    double? readProgress,
    Object? linkedNoteId = _sentinel,
    Object? topicId = _sentinel,
  }) {
    return WebArticle(
      id: id,
      url: url,
      title: title,
      author: author,
      extractedContent: extractedContent,
      savedAt: savedAt,
      readProgress: readProgress ?? this.readProgress,
      linkedNoteId: linkedNoteId == _sentinel ? this.linkedNoteId : linkedNoteId as String?,
      topicId: topicId == _sentinel ? this.topicId : topicId as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'author': author,
        'extractedContent': extractedContent,
        'savedAt': savedAt.toIso8601String(),
        'readProgress': readProgress,
        'linkedNoteId': linkedNoteId,
        'topicId': topicId,
      };

  factory WebArticle.fromJson(Map<String, dynamic> json) => WebArticle(
        id: json['id'] as String,
        url: json['url'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled Article',
        author: json['author'] as String?,
        extractedContent: json['extractedContent'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
        readProgress: (json['readProgress'] as num?)?.toDouble() ?? 0.0,
        linkedNoteId: json['linkedNoteId'] as String?,
        topicId: json['topicId'] as String?,
      );
}
