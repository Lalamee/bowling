class WarningDto {
  final String type;
  final String message;
  final int? equipmentId;
  final int? scheduleId;
  final int? partCatalogId;
  final DateTime? dueDate;

  const WarningDto({
    required this.type,
    required this.message,
    this.equipmentId,
    this.scheduleId,
    this.partCatalogId,
    this.dueDate,
  });

  factory WarningDto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;
    return WarningDto(
      type: json['type']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString() ?? '',
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      scheduleId: (json['scheduleId'] as num?)?.toInt(),
      partCatalogId: (json['partCatalogId'] as num?)?.toInt(),
      dueDate: _parseDate(json['dueDate']),
    );
  }
}
