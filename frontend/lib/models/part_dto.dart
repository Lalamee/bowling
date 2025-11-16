class PartDto {
  final int inventoryId;
  final int catalogId;
  final String catalogNumber;
  final String? officialNameEn;
  final String? officialNameRu;
  final String? commonName;
  final String? description;
  final int? quantity;
  final int? reservedQuantity; // TODO: reservedQuantity придёт из API склада
  final int? warehouseId;
  final String? location;
  final String? cellCode;
  final String? shelfCode;
  final int? laneNumber;
  final String? placementStatus;
  final bool? isUnique;
  final DateTime? lastChecked;
  final String? imageUrl;
  final String? diagramUrl;
  final int? equipmentNodeId;
  final List<int> equipmentNodePath;
  final List<String> compatibility;

  PartDto({
    required this.inventoryId,
    required this.catalogId,
    required this.catalogNumber,
    this.officialNameEn,
    this.officialNameRu,
    this.commonName,
    this.description,
    this.quantity,
    this.reservedQuantity,
    this.warehouseId,
    this.location,
    this.cellCode,
    this.shelfCode,
    this.laneNumber,
    this.placementStatus,
    this.isUnique,
    this.lastChecked,
    this.imageUrl,
    this.diagramUrl,
    this.equipmentNodeId,
    this.equipmentNodePath = const [],
    this.compatibility = const [],
  });

  factory PartDto.fromJson(Map<String, dynamic> json) {
    final inventoryId = _parseRequiredInt(
      json['inventoryId'] ?? json['inventory_id'] ?? json['id'],
      'inventoryId',
    );
    final catalogId = _parseRequiredInt(
      json['catalogId'] ?? json['catalog_id'] ?? json['id'],
      'catalogId',
    );

    return PartDto(
      inventoryId: inventoryId,
      catalogId: catalogId,
      catalogNumber: json['catalogNumber']?.toString() ?? '',
      officialNameEn: json['officialNameEn'] as String?,
      officialNameRu: json['officialNameRu'] as String?,
      commonName: json['commonName'] as String?,
      description: json['description'] as String?,
      quantity: _parseOptionalInt(json['quantity']),
      reservedQuantity: _parseOptionalInt(json['reservedQuantity'] ?? json['reserved_quantity']),
      warehouseId: _parseOptionalInt(json['warehouseId']),
      location: json['location']?.toString(),
      cellCode: json['cellCode']?.toString(),
      shelfCode: json['shelfCode']?.toString(),
      laneNumber: _parseOptionalInt(json['laneNumber']),
      placementStatus: json['placementStatus']?.toString(),
      isUnique: _parseOptionalBool(json['unique'] ?? json['isUnique']),
      lastChecked: _parseOptionalDate(json['lastChecked'] ?? json['last_checked']),
      imageUrl: json['imageUrl']?.toString(),
      diagramUrl: json['diagramUrl']?.toString(),
      equipmentNodeId: _parseOptionalInt(json['equipmentNodeId'])?.toInt(),
      equipmentNodePath: (json['equipmentNodePath'] as List?)
              ?.map((e) => _parseOptionalInt(e))
              .whereType<int>()
              .toList() ??
          const [],
      compatibility: (json['compatibility'] as List?)
              ?.map((e) => e?.toString())
              .whereType<String>()
              .toList() ??
          const [],
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
        'reservedQuantity': reservedQuantity,
        'warehouseId': warehouseId,
        'location': location,
        'cellCode': cellCode,
        'shelfCode': shelfCode,
        'laneNumber': laneNumber,
        'placementStatus': placementStatus,
        'unique': isUnique,
        'lastChecked': lastChecked?.toIso8601String(),
        'imageUrl': imageUrl,
        'diagramUrl': diagramUrl,
        'equipmentNodeId': equipmentNodeId,
        'equipmentNodePath': equipmentNodePath,
        'compatibility': compatibility,
      };
}

int _parseRequiredInt(dynamic value, String fieldName) {
  final parsed = _parseOptionalInt(value);
  if (parsed == null) {
    throw FormatException('Missing or invalid $fieldName');
  }
  return parsed;
}

int? _parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

bool? _parseOptionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
