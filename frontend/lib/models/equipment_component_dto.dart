class EquipmentComponentDto {
  final int componentId;
  final String name;
  final String? manufacturer;
  final String? category;
  final String? code;
  final String? notes;
  final int? parentId;

  EquipmentComponentDto({
    required this.componentId,
    required this.name,
    this.manufacturer,
    this.category,
    this.code,
    this.notes,
    this.parentId,
  });

  factory EquipmentComponentDto.fromJson(Map<String, dynamic> json) {
    return EquipmentComponentDto(
      componentId: (json['componentId'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      manufacturer: json['manufacturer'] as String?,
      category: json['category'] as String?,
      code: json['code'] as String?,
      notes: json['notes'] as String?,
      parentId: (json['parentId'] as num?)?.toInt(),
    );
  }
}
