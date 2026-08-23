import 'pdf_annotation.dart';

class PdfDocument {
  final String id;
  final String title;
  final String filePath;
  final int lastReadPage;
  final int? pageCount;
  final DateTime addedAt;
  final DateTime lastOpenedAt;
  final List<int> bookmarks;
  final String? linkedNoteId;
  final List<PdfAnnotation> annotations;
  final String? topicId;

  const PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    this.lastReadPage = 1,
    this.pageCount,
    required this.addedAt,
    required this.lastOpenedAt,
    this.bookmarks = const [],
    this.linkedNoteId,
    this.annotations = const [],
    this.topicId,
  });

  PdfDocument copyWith({
    String? title,
    String? filePath,
    int? lastReadPage,
    int? pageCount,
    DateTime? lastOpenedAt,
    List<int>? bookmarks,
    Object? linkedNoteId = _sentinel,
    List<PdfAnnotation>? annotations,
    Object? topicId = _sentinel,
  }) {
    return PdfDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      pageCount: pageCount ?? this.pageCount,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      bookmarks: bookmarks ?? this.bookmarks,
      linkedNoteId: linkedNoteId == _sentinel ? this.linkedNoteId : linkedNoteId as String?,
      annotations: annotations ?? this.annotations,
      topicId: topicId == _sentinel ? this.topicId : topicId as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'lastReadPage': lastReadPage,
        'pageCount': pageCount,
        'addedAt': addedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'bookmarks': bookmarks,
        'linkedNoteId': linkedNoteId,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'topicId': topicId,
      };

  factory PdfDocument.fromJson(Map<String, dynamic> json) => PdfDocument(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled PDF',
        filePath: json['filePath'] as String,
        lastReadPage: (json['lastReadPage'] as num?)?.toInt() ?? 1,
        pageCount: (json['pageCount'] as num?)?.toInt(),
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
        lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] as String? ?? '') ?? DateTime.now(),
        bookmarks: (json['bookmarks'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [],
        linkedNoteId: json['linkedNoteId'] as String?,
        annotations: (json['annotations'] as List<dynamic>?)
                ?.map((e) => PdfAnnotation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        topicId: json['topicId'] as String?,
      );
}
