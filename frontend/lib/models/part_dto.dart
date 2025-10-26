class PartDto {
  final int inventoryId;
  final int catalogId;
  final String catalogNumber;
  final String? officialNameEn;
  final String? officialNameRu;
  final String? commonName;
  final String? description;
  final int? quantity;
  final int? warehouseId;
  final String? location;
  final bool? isUnique;
  final DateTime? lastChecked;

  PartDto({
    required this.inventoryId,
    required this.catalogId,
    required this.catalogNumber,
    this.officialNameEn,
    this.officialNameRu,
    this.commonName,
    this.description,
    this.quantity,
    this.warehouseId,
    this.location,
    this.isUnique,
    this.lastChecked,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final dynamic rawInventoryId = json['inventoryId'] ?? json['inventory_id'] ?? json['id'];
    final dynamic rawCatalogId = json['catalogId'] ?? json['catalog_id'] ?? json['id'];

    return PartDto(
      inventoryId: (rawInventoryId as num).toInt(),
      catalogId: (rawCatalogId as num).toInt(),
      catalogNumber: json['catalogNumber']?.toString() ?? '',
      officialNameEn: json['officialNameEn'] as String?,
      officialNameRu: json['officialNameRu'] as String?,
      commonName: json['commonName'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      location: json['location']?.toString(),
      isUnique: json['unique'] as bool? ?? json['isUnique'] as bool?,
      lastChecked: parseDate(json['lastChecked'] ?? json['last_checked']),
    );
  }

  Map<String, dynamic> toJson() => {
        'inventoryId': inventoryId,
        'catalogId': catalogId,
        'catalogNumber': catalogNumber,
        'officialNameEn': officialNameEn,
        'officialNameRu': officialNameRu,
        'commonName': commonName,
        'description': description,
        'quantity': quantity,
        'warehouseId': warehouseId,
        'location': location,
        'unique': isUnique,
        'lastChecked': lastChecked?.toIso8601String(),
      };
}
