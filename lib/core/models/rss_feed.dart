class RssItem {
  final String id;
  final String title;
  final String link;
  final String description;
  final DateTime? publishedAt;

  const RssItem({
    required this.id,
    required this.title,
    required this.link,
    this.description = '',
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'description': description,
        'publishedAt': publishedAt?.toIso8601String(),
      };

  factory RssItem.fromJson(Map<String, dynamic> json) => RssItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        link: json['link'] as String? ?? '',
        description: json['description'] as String? ?? '',
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
      );
}

class RssFeed {
  final String id;
  final String title;
  final String url;
  final DateTime addedAt;
  final DateTime? lastRefreshedAt;
  final String? error;
  final List<RssItem> items;

  const RssFeed({
    required this.id,
    required this.title,
    required this.url,
    required this.addedAt,
    this.lastRefreshedAt,
    this.error,
    this.items = const [],
  });

  RssFeed copyWith({
    String? title,
    DateTime? lastRefreshedAt,
    Object? error = _sentinel,
    List<RssItem>? items,
  }) {
    return RssFeed(
      id: id,
      title: title ?? this.title,
      url: url,
      addedAt: addedAt,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      error: error == _sentinel ? this.error : error as String?,
      items: items ?? this.items,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'addedAt': addedAt.toIso8601String(),
        'lastRefreshedAt': lastRefreshedAt?.toIso8601String(),
        'error': error,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory RssFeed.fromJson(Map<String, dynamic> json) => RssFeed(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled feed',
        url: json['url'] as String? ?? '',
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
        lastRefreshedAt: json['lastRefreshedAt'] != null
            ? DateTime.tryParse(json['lastRefreshedAt'] as String)
            : null,
        error: json['error'] as String?,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => RssItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}