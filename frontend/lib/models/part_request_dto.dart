class PartRequestDto {
  final int clubId;
  final int? laneNumber;
  final int mechanicId;
  final String? managerNotes;
  final List<RequestedPartDto> requestedParts;

  PartRequestDto({
    required this.clubId,
    this.laneNumber,
    required this.mechanicId,
    this.managerNotes,
    required this.requestedParts,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'laneNumber': laneNumber,
        'mechanicId': mechanicId,
        'managerNotes': managerNotes,
        'requestedParts': requestedParts.map((e) => e.toJson()).toList(),
      };

  factory PartRequestDto.fromJson(Map<String, dynamic> json) {
    return PartRequestDto(
      clubId: (json['clubId'] as num).toInt(),
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      mechanicId: (json['mechanicId'] as num).toInt(),
      managerNotes: json['managerNotes'] as String?,
      requestedParts: (json['requestedParts'] as List<dynamic>)
          .map((e) => RequestedPartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class RequestedPartDto {
  final int? inventoryId;
  final int? catalogId;
  final String? catalogNumber;
  final String partName;
  final int quantity;
  final int? warehouseId;
  final String? location;

  RequestedPartDto({
    this.inventoryId,
    this.catalogId,
    this.catalogNumber,
    required this.partName,
    required this.quantity,
    this.warehouseId,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'inventoryId': inventoryId,
        'catalogId': catalogId,
        'catalogNumber': catalogNumber,
        'partName': partName,
        'quantity': quantity,
        'warehouseId': warehouseId,
        'location': location,
      };

  factory RequestedPartDto.fromJson(Map<String, dynamic> json) {
    int _parseId(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final dynamic inventoryRaw = json['inventoryId'] ?? json['inventory_id'];
    final dynamic catalogRaw = json['catalogId'] ?? json['catalog_id'];
    return RequestedPartDto(
      inventoryId: inventoryRaw != null ? _parseId(inventoryRaw) : null,
      catalogId: catalogRaw != null ? _parseId(catalogRaw) : null,
      catalogNumber: json['catalogNumber']?.toString(),
      partName: json['partName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      location: json['location']?.toString(),
    );
  }
}
