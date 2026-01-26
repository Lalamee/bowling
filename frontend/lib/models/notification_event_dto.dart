enum NotificationEventType {
  mechanicHelpRequested,
  mechanicHelpConfirmed,
  mechanicHelpDeclined,
  mechanicHelpReassigned,
  maintenanceWarning,
  clubAccessRequest,
  supplierComplaintUpdate,
  staffAccessRequest,
  staffAccessRevocation,
  technicalAssistance,
  adminResponse,
  freeMechanicApproved,
  clubTechSupport,
  clubSupplierRefusal,
  clubMechanicFailure,
  clubLegalAssistance,
  clubSpecialistAccess,
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
      case 'MAINTENANCE_WARNING':
        return NotificationEventType.maintenanceWarning;
      case 'CLUB_ACCESS_REQUEST':
        return NotificationEventType.clubAccessRequest;
      case 'SUPPLIER_COMPLAINT_UPDATE':
        return NotificationEventType.supplierComplaintUpdate;
      case 'STAFF_ACCESS_REQUEST':
        return NotificationEventType.staffAccessRequest;
      case 'STAFF_ACCESS_REVOCATION':
      case 'STAFF_ACCESS_REVOKE':
        return NotificationEventType.staffAccessRevocation;
      case 'TECH_SUPPORT_REQUEST':
      case 'TECHNICAL_ASSISTANCE':
        return NotificationEventType.technicalAssistance;
      case 'ADMIN_RESPONSE':
      case 'ADMIN_REPLY':
        return NotificationEventType.adminResponse;
      case 'CLUB_TECH_SUPPORT':
        return NotificationEventType.clubTechSupport;
      case 'CLUB_SUPPLIER_REFUSAL':
        return NotificationEventType.clubSupplierRefusal;
      case 'CLUB_MECHANIC_FAILURE':
        return NotificationEventType.clubMechanicFailure;
      case 'CLUB_LEGAL_ASSISTANCE':
        return NotificationEventType.clubLegalAssistance;
      case 'CLUB_SPECIALIST_ACCESS':
        return NotificationEventType.clubSpecialistAccess;
      case 'FREE_MECHANIC_APPROVED':
        return NotificationEventType.freeMechanicApproved;
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
      case NotificationEventType.maintenanceWarning:
        return 'Предупреждение по ТО';
      case NotificationEventType.clubAccessRequest:
        return 'Запрос доступа к клубу';
      case NotificationEventType.supplierComplaintUpdate:
        return 'Статус спора с поставщиком';
      case NotificationEventType.staffAccessRequest:
        return 'Запрос на доступ/лишение доступа';
      case NotificationEventType.staffAccessRevocation:
        return 'Доступ сотрудника изменён';
      case NotificationEventType.technicalAssistance:
        return 'Запрос техпомощи/сервиса';
      case NotificationEventType.adminResponse:
        return 'Ответ Администрации';
      case NotificationEventType.freeMechanicApproved:
        return 'Свободный механик подтвержден';
      case NotificationEventType.clubTechSupport:
        return 'Запрос техпомощи';
      case NotificationEventType.clubSupplierRefusal:
        return 'Отказ поставщика';
      case NotificationEventType.clubMechanicFailure:
        return 'Ремонт невозможен';
      case NotificationEventType.clubLegalAssistance:
        return 'Юридическая помощь';
      case NotificationEventType.clubSpecialistAccess:
        return 'Запрос доступа к базе специалистов';
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

  bool get isWarningEvent => typeKey == NotificationEventType.maintenanceWarning;

  bool get isSupplierComplaint =>
      typeKey == NotificationEventType.supplierComplaintUpdate ||
      typeKey == NotificationEventType.clubSupplierRefusal;

  bool get isAccessRequest =>
      typeKey == NotificationEventType.clubAccessRequest ||
      typeKey == NotificationEventType.clubSpecialistAccess;

  bool get isStaffAccess =>
      typeKey == NotificationEventType.staffAccessRequest || typeKey == NotificationEventType.staffAccessRevocation;

  bool get isTechSupport =>
      typeKey == NotificationEventType.technicalAssistance ||
      typeKey == NotificationEventType.clubTechSupport;

  bool get isAdminReply => typeKey == NotificationEventType.adminResponse;

  bool get isFreeMechanicEvent => typeKey == NotificationEventType.freeMechanicApproved;

  factory NotificationEventDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value is! String || value.isEmpty) return null;
      final normalized = _normalizeBackendDate(value);
      return DateTime.tryParse(normalized);
    }

    String _normalizeBackendDate(String raw) {
      final trimmed = raw.trim();
      final hasTimezone = trimmed.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);
      if (hasTimezone) return trimmed;
      return '${trimmed}Z';
    }

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
