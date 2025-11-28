class PartsCatalogResponseDto {
  final int catalogId;
  final int? manufacturerId;
  final String? manufacturerName;
  final String catalogNumber;
  final String? officialNameEn;
  final String? officialNameRu;
  final String? commonName;
  final String? description;
  final int? normalServiceLife;
  final String? unit;
  final bool? isUnique;
  final String? categoryCode;
  final int? availableQuantity;
  final String? availabilityStatus; // keep as string for simplicity
  final String? imageUrl;
  final String? diagramUrl;
  final int? equipmentNodeId;
  final List<int> equipmentNodePath;
  final List<String> compatibility;

  PartsCatalogResponseDto({
    required this.catalogId,
    required this.catalogNumber,
    this.manufacturerId,
    this.manufacturerName,
    this.officialNameEn,
    this.officialNameRu,
    this.commonName,
    this.description,
    this.normalServiceLife,
    this.unit,
    this.isUnique,
    this.categoryCode,
    this.availableQuantity,
    this.availabilityStatus,
    this.imageUrl,
    this.diagramUrl,
    this.equipmentNodeId,
    this.equipmentNodePath = const [],
    this.compatibility = const [],
  });

  factory PartsCatalogResponseDto.fromJson(Map<String, dynamic> json) {
    return PartsCatalogResponseDto(
      catalogId: (json['catalogId'] as num).toInt(),
      manufacturerId: (json['manufacturerId'] as num?)?.toInt(),
      manufacturerName: json['manufacturerName'] as String?,
      catalogNumber: json['catalogNumber'] as String,
      officialNameEn: json['officialNameEn'] as String?,
      officialNameRu: json['officialNameRu'] as String?,
      commonName: json['commonName'] as String?,
      description: json['description'] as String?,
      normalServiceLife: (json['normalServiceLife'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      isUnique: json['isUnique'] as bool?,
      categoryCode: json['categoryCode']?.toString(),
      availableQuantity: (json['availableQuantity'] as num?)?.toInt(),
      availabilityStatus: json['availabilityStatus']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      diagramUrl: json['diagramUrl']?.toString(),
      equipmentNodeId: (json['equipmentNodeId'] as num?)?.toInt(),
      equipmentNodePath: (json['equipmentNodePath'] as List?)
              ?.map((e) => (e as num?)?.toInt())
              .whereType<int>()
              .toList() ??
          const [],
      compatibility: (json['compatibleEquipment'] as List?)
              ?.map((e) => e?.toString())
              .whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'catalogId': catalogId,
        'manufacturerId': manufacturerId,
        'manufacturerName': manufacturerName,
        'catalogNumber': catalogNumber,
        'officialNameEn': officialNameEn,
        'officialNameRu': officialNameRu,
        'commonName': commonName,
        'description': description,
        'normalServiceLife': normalServiceLife,
        'unit': unit,
        'isUnique': isUnique,
        'categoryCode': categoryCode,
        'availableQuantity': availableQuantity,
        'availabilityStatus': availabilityStatus,
        'imageUrl': imageUrl,
        'diagramUrl': diagramUrl,
        'equipmentNodeId': equipmentNodeId,
        'equipmentNodePath': equipmentNodePath,
        'compatibleEquipment': compatibility,
      };
}
