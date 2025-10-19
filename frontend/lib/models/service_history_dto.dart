import 'service_history_part_dto.dart';

class ServiceHistoryDto {
  final int? serviceId;
  final int clubId;
  final String? clubName;
  final int? equipmentId;
  final String? equipmentName;
  final int? laneNumber;
  final String serviceType;
  final DateTime? serviceDate;
  final String description;
  final String? partsReplaced;
  final double? laborHours;
  final double? totalCost;
  final int performedByMechanicId;
  final String? performedByMechanicName;
  final int? supervisedByUserId;
  final String? supervisedByUserName;
  final DateTime? nextServiceDue;
  final DateTime? warrantyUntil;
  final String? serviceNotes;
  final String? performanceMetrics;
  final List<String>? photos;
  final List<String>? documents;
  final DateTime? createdDate;
  final int? createdBy;
  final String? createdByName;
  final List<ServiceHistoryPartDto>? partsUsed;

  ServiceHistoryDto({
    this.serviceId,
    required this.clubId,
    this.clubName,
    this.equipmentId,
    this.equipmentName,
    this.laneNumber,
    required this.serviceType,
    this.serviceDate,
    required this.description,
    this.partsReplaced,
    this.laborHours,
    this.totalCost,
    required this.performedByMechanicId,
    this.performedByMechanicName,
    this.supervisedByUserId,
    this.supervisedByUserName,
    this.nextServiceDue,
    this.warrantyUntil,
    this.serviceNotes,
    this.performanceMetrics,
    this.photos,
    this.documents,
    this.createdDate,
    this.createdBy,
    this.createdByName,
    this.partsUsed,
  });

  factory ServiceHistoryDto.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    List<String>? ls(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : null;
    return ServiceHistoryDto(
      serviceId: (json['serviceId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num).toInt(),
      clubName: json['clubName'] as String?,
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      equipmentName: json['equipmentName'] as String?,
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      serviceType: json['serviceType'] as String,
      serviceDate: d(json['serviceDate']),
      description: json['description'] as String,
      partsReplaced: json['partsReplaced'] as String?,
      laborHours: f(json['laborHours']),
      totalCost: f(json['totalCost']),
      performedByMechanicId: (json['performedByMechanicId'] as num).toInt(),
      performedByMechanicName: json['performedByMechanicName'] as String?,
      supervisedByUserId: (json['supervisedByUserId'] as num?)?.toInt(),
      supervisedByUserName: json['supervisedByUserName'] as String?,
      nextServiceDue: d(json['nextServiceDue']),
      warrantyUntil: d(json['warrantyUntil']),
      serviceNotes: json['serviceNotes'] as String?,
      performanceMetrics: json['performanceMetrics'] as String?,
      photos: ls(json['photos']),
      documents: ls(json['documents']),
      createdDate: d(json['createdDate']),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdByName: json['createdByName'] as String?,
      partsUsed: (json['partsUsed'] as List?)
          ?.map((e) => ServiceHistoryPartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'clubId': clubId,
        'clubName': clubName,
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'laneNumber': laneNumber,
        'serviceType': serviceType,
        'serviceDate': serviceDate?.toIso8601String(),
        'description': description,
        'partsReplaced': partsReplaced,
        'laborHours': laborHours,
        'totalCost': totalCost,
        'performedByMechanicId': performedByMechanicId,
        'performedByMechanicName': performedByMechanicName,
        'supervisedByUserId': supervisedByUserId,
        'supervisedByUserName': supervisedByUserName,
        'nextServiceDue': nextServiceDue?.toIso8601String(),
        'warrantyUntil': warrantyUntil?.toIso8601String(),
        'serviceNotes': serviceNotes,
        'performanceMetrics': performanceMetrics,
        'photos': photos,
        'documents': documents,
        'createdDate': createdDate?.toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'partsUsed': partsUsed?.map((e) => e.toJson()).toList(),
      };
}
