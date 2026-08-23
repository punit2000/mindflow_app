/// A user-created topic used to organise reading library items (PDFs,
/// Wikipedia pages, web articles) into subject-based groups.
class ReadingTopic {
  final String id;
  final String name;
  final int colorIndex;

  const ReadingTopic({
    required this.id,
    required this.name,
    this.colorIndex = 0,
  });

  ReadingTopic copyWith({
    String? name,
    int? colorIndex,
  }) {
    return ReadingTopic(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
      };

  factory ReadingTopic.fromJson(Map<String, dynamic> json) => ReadingTopic(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Topic',
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      );
}