class MaintenanceScheduleDto {
  final int? scheduleId;
  final String? maintenanceType;
  final DateTime? scheduledDate;
  final DateTime? lastPerformed;
  final bool? critical;

  MaintenanceScheduleDto({
    this.scheduleId,
    this.maintenanceType,
    this.scheduledDate,
    this.lastPerformed,
    this.critical,
  });

  factory MaintenanceScheduleDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return MaintenanceScheduleDto(
      scheduleId: (json['scheduleId'] as num?)?.toInt(),
      maintenanceType: json['maintenanceType'] as String?,
      scheduledDate: _parseDate(json['scheduledDate']),
      lastPerformed: _parseDate(json['lastPerformed']),
      critical: json['critical'] as bool?,
    );
  }
}
