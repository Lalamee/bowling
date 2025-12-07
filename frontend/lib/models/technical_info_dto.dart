import 'equipment_component_dto.dart';
import 'maintenance_schedule_dto.dart';

class TechnicalInfoDto {
  final int? equipmentId;
  final String? model;
  final String? serialNumber;
  final String? equipmentType;
  final String? manufacturer;
  final int? productionYear;
  final int? lanesCount;
  final int? conditionPercentage;
  final DateTime? purchaseDate;
  final DateTime? warrantyUntil;
  final String? status;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final List<EquipmentComponentDto> components;
  final List<MaintenanceScheduleDto> schedules;

  TechnicalInfoDto({
    this.equipmentId,
    this.model,
    this.serialNumber,
    this.equipmentType,
    this.manufacturer,
    this.productionYear,
    this.lanesCount,
    this.conditionPercentage,
    this.purchaseDate,
    this.warrantyUntil,
    this.status,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.components = const [],
    this.schedules = const [],
  });

  factory TechnicalInfoDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return TechnicalInfoDto(
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      equipmentType: json['equipmentType'] as String?,
      manufacturer: json['manufacturer'] as String?,
      productionYear: (json['productionYear'] as num?)?.toInt(),
      lanesCount: (json['lanesCount'] as num?)?.toInt(),
      conditionPercentage: (json['conditionPercentage'] as num?)?.toInt(),
      purchaseDate: _parseDate(json['purchaseDate']),
      warrantyUntil: _parseDate(json['warrantyUntil']),
      status: json['status'] as String?,
      lastMaintenanceDate: _parseDate(json['lastMaintenanceDate']),
      nextMaintenanceDate: _parseDate(json['nextMaintenanceDate']),
      components: (json['components'] as List?)
              ?.map((e) => EquipmentComponentDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      schedules: (json['schedules'] as List?)
              ?.map((e) => MaintenanceScheduleDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
