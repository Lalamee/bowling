import 'work_log_part_usage_dto.dart';

class ServiceJournalEntryDto {
  final int? workLogId;
  final int? requestId;
  final int? serviceHistoryId;
  final int? laneNumber;
  final int? equipmentId;
  final String? equipmentModel;
  final String? workType;
  final String? serviceType;
  final String? status;
  final String? requestStatus;
  final DateTime? createdDate;
  final DateTime? completedDate;
  final DateTime? serviceDate;
  final String? mechanicName;
  final List<WorkLogPartUsageDto> partsUsed;

  ServiceJournalEntryDto({
    this.workLogId,
    this.requestId,
    this.serviceHistoryId,
    this.laneNumber,
    this.equipmentId,
    this.equipmentModel,
    this.workType,
    this.serviceType,
    this.status,
    this.requestStatus,
    this.createdDate,
    this.completedDate,
    this.serviceDate,
    this.mechanicName,
    this.partsUsed = const [],
  });

  factory ServiceJournalEntryDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;
    return ServiceJournalEntryDto(
      workLogId: (json['workLogId'] as num?)?.toInt(),
      requestId: (json['requestId'] as num?)?.toInt(),
      serviceHistoryId: (json['serviceHistoryId'] as num?)?.toInt(),
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      equipmentModel: json['equipmentModel'] as String?,
      workType: json['workType']?.toString(),
      serviceType: json['serviceType']?.toString(),
      status: json['status']?.toString(),
      requestStatus: json['requestStatus']?.toString(),
      createdDate: _parseDate(json['createdDate']),
      completedDate: _parseDate(json['completedDate']),
      serviceDate: _parseDate(json['serviceDate']),
      mechanicName: json['mechanicName'] as String?,
      partsUsed: (json['partsUsed'] as List?)
              ?.map((e) => WorkLogPartUsageDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
