class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final items = (json['content'] as List? ?? [])
        .map((e) => fromItem(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PageResponse<T>(
      content: items,
      totalElements: (json['totalElements'] as num? ?? items.length).toInt(),
      totalPages: (json['totalPages'] as num? ?? 1).toInt(),
      size: (json['size'] as num? ?? items.length).toInt(),
      number: (json['number'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toItem) => {
        'content': content.map((e) => toItem(e)).toList(),
        'totalElements': totalElements,
        'totalPages': totalPages,
        'size': size,
        'number': number,
      };
}
