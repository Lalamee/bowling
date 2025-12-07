class WarehouseSummaryDto {
  final int warehouseId;
  final int? clubId;
  final String title;
  final String warehouseType; // CLUB / PERSONAL
  final int? totalPositions;
  final int? lowStockPositions;
  final int? reservedPositions;
  final bool personalAccess;
  final String? description;
  final String? locationReference;

  const WarehouseSummaryDto({
    required this.warehouseId,
    this.clubId,
    required this.title,
    required this.warehouseType,
    this.totalPositions,
    this.lowStockPositions,
    this.reservedPositions,
    this.personalAccess = false,
    this.description,
    this.locationReference,
  });

  factory WarehouseSummaryDto.fromJson(Map<String, dynamic> json) {
    return WarehouseSummaryDto(
      warehouseId: _parseRequiredInt(json['warehouseId'], 'warehouseId'),
      clubId: _parseOptionalInt(json['clubId']),
      title: json['clubName']?.toString() ?? json['title']?.toString() ?? 'Склад',
      warehouseType: json['warehouseType']?.toString() ?? json['type']?.toString() ?? 'CLUB',
      totalPositions: _parseOptionalInt(json['totalPositions']),
      lowStockPositions: _parseOptionalInt(json['lowStockPositions']),
      reservedPositions: _parseOptionalInt(json['reservedPositions']),
      personalAccess: json['personalAccess'] == true,
      description: json['description']?.toString(),
      locationReference: (json['locationReference'] ?? json['location'])?.toString(),
    );
  }
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
