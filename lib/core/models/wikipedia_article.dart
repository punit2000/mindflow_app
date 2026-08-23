class WikipediaArticle {
  const WikipediaArticle({
    required this.title,
    required this.content,
    required this.lastReadPage,
    required this.lastOpenedAt,
    this.bookmarkedPages = const [],
    this.linkedNoteId,
    this.topicId,
  });

  final String title;
  final String content;
  final int lastReadPage;
  final DateTime lastOpenedAt;
  final List<int> bookmarkedPages;
  final String? linkedNoteId;
  final String? topicId;

  WikipediaArticle copyWith({
    int? lastReadPage,
    DateTime? lastOpenedAt,
    List<int>? bookmarkedPages,
    Object? linkedNoteId = _sentinel,
    Object? topicId = _sentinel,
  }) {
    return WikipediaArticle(
      title: title,
      content: content,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      bookmarkedPages: bookmarkedPages ?? this.bookmarkedPages,
      linkedNoteId: linkedNoteId == _sentinel ? this.linkedNoteId : linkedNoteId as String?,
      topicId: topicId == _sentinel ? this.topicId : topicId as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'lastReadPage': lastReadPage,
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'bookmarkedPages': bookmarkedPages,
        'linkedNoteId': linkedNoteId,
        'topicId': topicId,
      };

  factory WikipediaArticle.fromJson(Map<String, dynamic> json) => WikipediaArticle(
        title: json['title'] as String,
        content: json['content'] as String,
        lastReadPage: (json['lastReadPage'] as num?)?.toInt() ?? 0,
        lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] as String? ?? '') ?? DateTime.now(),
        bookmarkedPages: (json['bookmarkedPages'] as List<dynamic>?)
                ?.map((page) => (page as num).toInt())
                .toList() ??
            const [],
        linkedNoteId: json['linkedNoteId'] as String?,
        topicId: json['topicId'] as String?,
      );
}
