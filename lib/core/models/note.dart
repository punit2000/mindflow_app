class ChecklistItem {
  final String id;
  final String text;
  final bool isChecked;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final int colorIndex;
  final List<String> tags;
  final String? folder;
  final bool isPinned;
  final bool isArchived;
  final bool isChecklist;
  final List<ChecklistItem> checklistItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedSourceId; // id of linked PDF/Wikipedia/WebArticle

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.colorIndex = 0,
    this.tags = const [],
    this.folder,
    this.isPinned = false,
    this.isArchived = false,
    this.isChecklist = false,
    this.checklistItems = const [],
    required this.createdAt,
    required this.updatedAt,
    this.linkedSourceId,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    int? colorIndex,
    List<String>? tags,
    Object? folder = _sentinel,
    bool? isPinned,
    bool? isArchived,
    bool? isChecklist,
    List<ChecklistItem>? checklistItems,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? linkedSourceId = _sentinel,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorIndex: colorIndex ?? this.colorIndex,
      tags: tags ?? this.tags,
      folder: folder == _sentinel ? this.folder : folder as String?,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isChecklist: isChecklist ?? this.isChecklist,
      checklistItems: checklistItems ?? this.checklistItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedSourceId: linkedSourceId == _sentinel ? this.linkedSourceId : linkedSourceId as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'colorIndex': colorIndex,
      'tags': tags,
      'folder': folder,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isChecklist': isChecklist,
      'checklistItems': checklistItems.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'linkedSourceId': linkedSourceId,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      colorIndex: json['colorIndex'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      folder: json['folder'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isChecklist: json['isChecklist'] as bool? ?? false,
      checklistItems: (json['checklistItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      linkedSourceId: json['linkedSourceId'] as String?,
    );
  }
}
