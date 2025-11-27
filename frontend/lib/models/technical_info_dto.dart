import 'equipment_component_dto.dart';
import 'maintenance_schedule_dto.dart';

class TechnicalInfoDto {
  final int? equipmentId;
  final String? model;
  final int? productionYear;
  final int? lanesCount;
  final int? conditionPercentage;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final List<EquipmentComponentDto> components;
  final List<MaintenanceScheduleDto> schedules;

  TechnicalInfoDto({
    this.equipmentId,
    this.model,
    this.productionYear,
    this.lanesCount,
    this.conditionPercentage,
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
      productionYear: (json['productionYear'] as num?)?.toInt(),
      lanesCount: (json['lanesCount'] as num?)?.toInt(),
      conditionPercentage: (json['conditionPercentage'] as num?)?.toInt(),
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
