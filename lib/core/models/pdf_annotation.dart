/// A drawn annotation attached to a PDF page.
///
/// Coordinates are normalized (0.0–1.0) relative to the annotation canvas so
/// they remain roughly correct when the viewer widget resizes.
class PdfAnnotation {
  final String id;
  final int page;
  final String type; // 'highlight' | 'underline' | 'ink'
  final int colorIndex;
  final List<List<double>> points; // normalized [dx, dy] pairs

  const PdfAnnotation({
    required this.id,
    required this.page,
    required this.type,
    required this.colorIndex,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'type': type,
        'colorIndex': colorIndex,
        'points': points,
      };

  factory PdfAnnotation.fromJson(Map<String, dynamic> json) => PdfAnnotation(
        id: json['id'] as String? ?? '',
        page: (json['page'] as num?)?.toInt() ?? 1,
        type: json['type'] as String? ?? 'ink',
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => (p as List<dynamic>)
                    .map((e) => (e as num).toDouble())
                    .toList())
                .toList() ??
            const [],
      );
}