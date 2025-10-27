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
      warehouseId: _parseOptionalInt(json['warehouseId']),
      location: json['location']?.toString(),
      isUnique: _parseOptionalBool(json['unique'] ?? json['isUnique']),
      lastChecked: _parseOptionalDate(json['lastChecked'] ?? json['last_checked']),
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
