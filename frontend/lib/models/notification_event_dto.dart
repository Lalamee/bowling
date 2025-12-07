enum NotificationEventType {
  mechanicHelpRequested,
  mechanicHelpConfirmed,
  mechanicHelpDeclined,
  mechanicHelpReassigned,
  unknown;

  static NotificationEventType fromBackend(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    switch (normalized) {
      case 'MECHANIC_HELP_REQUESTED':
        return NotificationEventType.mechanicHelpRequested;
      case 'MECHANIC_HELP_CONFIRMED':
        return NotificationEventType.mechanicHelpConfirmed;
      case 'MECHANIC_HELP_DECLINED':
        return NotificationEventType.mechanicHelpDeclined;
      case 'MECHANIC_HELP_REASSIGNED':
        return NotificationEventType.mechanicHelpReassigned;
      default:
        return NotificationEventType.unknown;
    }
  }

  String label() {
    switch (this) {
      case NotificationEventType.mechanicHelpRequested:
        return 'Механик запросил помощь';
      case NotificationEventType.mechanicHelpConfirmed:
        return 'Запрос помощи подтвержден';
      case NotificationEventType.mechanicHelpDeclined:
        return 'Запрос помощи отклонен';
      case NotificationEventType.mechanicHelpReassigned:
        return 'Назначен другой специалист';
      case NotificationEventType.unknown:
      default:
        return 'Оповещение';
    }
  }
}

class NotificationEventDto {
  final String id;
  final String type;
  final NotificationEventType typeKey;
  final String message;
  final int? requestId;
  final int? workLogId;
  final int? mechanicId;
  final int? clubId;
  final List<int> partIds;
  final String? payload;
  final DateTime? createdAt;
  final List<String> audiences;

  const NotificationEventDto({
    required this.id,
    required this.type,
    required this.typeKey,
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

  bool get isHelpEvent =>
      typeKey == NotificationEventType.mechanicHelpRequested ||
      typeKey == NotificationEventType.mechanicHelpConfirmed ||
      typeKey == NotificationEventType.mechanicHelpDeclined ||
      typeKey == NotificationEventType.mechanicHelpReassigned;

  factory NotificationEventDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    final rawType = json['type']?.toString();
    final parsedType = NotificationEventType.fromBackend(rawType);

    return NotificationEventDto(
      id: json['id']?.toString() ?? '',
      type: rawType ?? 'UNKNOWN',
      typeKey: parsedType,
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
