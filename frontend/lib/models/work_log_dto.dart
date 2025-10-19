import 'work_log_part_usage_dto.dart';
import 'work_log_status_history_dto.dart';

class WorkLogDto {
  final int? logId;
  final int? maintenanceRequestId;
  final int clubId;
  final String? clubName;
  final int? laneNumber;
  final int? equipmentId;
  final int mechanicId;
  final String? mechanicName;
  final DateTime? createdDate;
  final DateTime? startedDate;
  final DateTime? completedDate;
  final String status;
  final String workType;
  final String problemDescription;
  final String? workPerformed;
  final String? solutionDescription;
  final double? estimatedHours;
  final double? actualHours;
  final double? laborCost;
  final double? totalPartsCost;
  final double? totalCost;
  final int? priority;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvalDate;
  final String? managerNotes;
  final int? qualityRating;
  final int? customerSatisfaction;
  final List<String>? photos;
  final int? warrantyPeriodMonths;
  final DateTime? nextServiceDate;
  final int? createdBy;
  final String? createdByName;
  final int? modifiedBy;
  final String? modifiedByName;
  final DateTime? modifiedDate;
  final bool? isManualEdit;
  final String? manualEditReason;
  final List<WorkLogPartUsageDto>? partsUsed;
  final List<WorkLogStatusHistoryDto>? statusHistory;

  WorkLogDto({
    this.logId,
    this.maintenanceRequestId,
    required this.clubId,
    this.clubName,
    this.laneNumber,
    this.equipmentId,
    required this.mechanicId,
    this.mechanicName,
    this.createdDate,
    this.startedDate,
    this.completedDate,
    required this.status,
    required this.workType,
    required this.problemDescription,
    this.workPerformed,
    this.solutionDescription,
    this.estimatedHours,
    this.actualHours,
    this.laborCost,
    this.totalPartsCost,
    this.totalCost,
    this.priority,
    this.approvedBy,
    this.approvedByName,
    this.approvalDate,
    this.managerNotes,
    this.qualityRating,
    this.customerSatisfaction,
    this.photos,
    this.warrantyPeriodMonths,
    this.nextServiceDate,
    this.createdBy,
    this.createdByName,
    this.modifiedBy,
    this.modifiedByName,
    this.modifiedDate,
    this.isManualEdit,
    this.manualEditReason,
    this.partsUsed,
    this.statusHistory,
  });

  factory WorkLogDto.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    List<String>? ls(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : null;
    return WorkLogDto(
      logId: (json['logId'] as num?)?.toInt(),
      maintenanceRequestId: (json['maintenanceRequestId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num).toInt(),
      clubName: json['clubName'] as String?,
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      mechanicId: (json['mechanicId'] as num).toInt(),
      mechanicName: json['mechanicName'] as String?,
      createdDate: d(json['createdDate']),
      startedDate: d(json['startedDate']),
      completedDate: d(json['completedDate']),
      status: json['status'] as String,
      workType: json['workType'] as String,
      problemDescription: json['problemDescription'] as String,
      workPerformed: json['workPerformed'] as String?,
      solutionDescription: json['solutionDescription'] as String?,
      estimatedHours: f(json['estimatedHours']),
      actualHours: f(json['actualHours']),
      laborCost: f(json['laborCost']),
      totalPartsCost: f(json['totalPartsCost']),
      totalCost: f(json['totalCost']),
      priority: (json['priority'] as num?)?.toInt(),
      approvedBy: (json['approvedBy'] as num?)?.toInt(),
      approvedByName: json['approvedByName'] as String?,
      approvalDate: d(json['approvalDate']),
      managerNotes: json['managerNotes'] as String?,
      qualityRating: (json['qualityRating'] as num?)?.toInt(),
      customerSatisfaction: (json['customerSatisfaction'] as num?)?.toInt(),
      photos: ls(json['photos']),
      warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt(),
      nextServiceDate: d(json['nextServiceDate']),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdByName: json['createdByName'] as String?,
      modifiedBy: (json['modifiedBy'] as num?)?.toInt(),
      modifiedByName: json['modifiedByName'] as String?,
      modifiedDate: d(json['modifiedDate']),
      isManualEdit: json['isManualEdit'] as bool?,
      manualEditReason: json['manualEditReason'] as String?,
      partsUsed: (json['partsUsed'] as List?)?.map((e) => WorkLogPartUsageDto.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      statusHistory: (json['statusHistory'] as List?)?.map((e) => WorkLogStatusHistoryDto.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'maintenanceRequestId': maintenanceRequestId,
        'clubId': clubId,
        'clubName': clubName,
        'laneNumber': laneNumber,
        'equipmentId': equipmentId,
        'mechanicId': mechanicId,
        'mechanicName': mechanicName,
        'createdDate': createdDate?.toIso8601String(),
        'startedDate': startedDate?.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
        'status': status,
        'workType': workType,
        'problemDescription': problemDescription,
        'workPerformed': workPerformed,
        'solutionDescription': solutionDescription,
        'estimatedHours': estimatedHours,
        'actualHours': actualHours,
        'laborCost': laborCost,
        'totalPartsCost': totalPartsCost,
        'totalCost': totalCost,
        'priority': priority,
        'approvedBy': approvedBy,
        'approvedByName': approvedByName,
        'approvalDate': approvalDate?.toIso8601String(),
        'managerNotes': managerNotes,
        'qualityRating': qualityRating,
        'customerSatisfaction': customerSatisfaction,
        'photos': photos,
        'warrantyPeriodMonths': warrantyPeriodMonths,
        'nextServiceDate': nextServiceDate?.toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'modifiedBy': modifiedBy,
        'modifiedByName': modifiedByName,
        'modifiedDate': modifiedDate?.toIso8601String(),
        'isManualEdit': isManualEdit,
        'manualEditReason': manualEditReason,
        'partsUsed': partsUsed?.map((e) => e.toJson()).toList(),
        'statusHistory': statusHistory?.map((e) => e.toJson()).toList(),
      };
}
