class EquipmentCategoryDto {
  final int id;
  final int? parentId;
  final int level;
  final String brand;
  final String? nameRu;
  final String? nameEn;
  final int? sortOrder;
  final bool active;

  EquipmentCategoryDto({
    required this.id,
    this.parentId,
    required this.level,
    required this.brand,
    this.nameRu,
    this.nameEn,
    this.sortOrder,
    required this.active,
  });

  factory EquipmentCategoryDto.fromJson(Map<String, dynamic> json) {
    return EquipmentCategoryDto(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      level: (json['level'] as num).toInt(),
      brand: json['brand'] as String? ?? '',
      nameRu: json['nameRu'] as String?,
      nameEn: json['nameEn'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      active: json['active'] as bool? ?? false,
    );
  }

  String get displayName => nameRu?.isNotEmpty == true ? nameRu! : (nameEn ?? '');
}
