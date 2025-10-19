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
  final int? availableQuantity;
  final String? availabilityStatus; // keep as string for simplicity

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
    this.availableQuantity,
    this.availabilityStatus,
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
      availableQuantity: (json['availableQuantity'] as num?)?.toInt(),
      availabilityStatus: json['availabilityStatus']?.toString(),
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
        'availableQuantity': availableQuantity,
        'availabilityStatus': availabilityStatus,
      };
}
