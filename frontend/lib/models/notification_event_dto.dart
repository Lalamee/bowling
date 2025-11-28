class NotificationEventDto {
  final String id;
  final String type;
  final String message;
  final int? requestId;
  final int? workLogId;
  final int? mechanicId;
  final int? clubId;
  final List<int> partIds;
  final String? payload;
  final DateTime? createdAt;
  final List<String> audiences;

  NotificationEventDto({
    required this.id,
    required this.type,
    required this.message,
    this.requestId,
    this.workLogId,
    this.mechanicId,
    this.clubId,
    this.partIds = const [],
    this.payload,
    this.createdAt,
    this.audiences = const [],
  });

  factory NotificationEventDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return NotificationEventDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString() ?? '',
      requestId: (json['requestId'] as num?)?.toInt(),
      workLogId: (json['workLogId'] as num?)?.toInt(),
      mechanicId: (json['mechanicId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      partIds: (json['partIds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
      payload: json['payload']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      audiences: (json['audiences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
