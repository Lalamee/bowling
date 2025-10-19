class ServiceHistoryPartDto {
  final int? id;
  final int? serviceHistoryId;
  final int? partCatalogId;
  final String partName;
  final String catalogNumber;
  final int quantity;
  final double unitCost;
  final double? totalCost;
  final int? warrantyMonths;
  final int? supplierId;
  final String? supplierName;
  final String? installationNotes;
  final DateTime? createdDate;

  ServiceHistoryPartDto({
    this.id,
    this.serviceHistoryId,
    this.partCatalogId,
    required this.partName,
    required this.catalogNumber,
    required this.quantity,
    required this.unitCost,
    this.totalCost,
    this.warrantyMonths,
    this.supplierId,
    this.supplierName,
    this.installationNotes,
    this.createdDate,
  });

  factory ServiceHistoryPartDto.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    return ServiceHistoryPartDto(
      id: (json['id'] as num?)?.toInt(),
      serviceHistoryId: (json['serviceHistoryId'] as num?)?.toInt(),
      partCatalogId: (json['partCatalogId'] as num?)?.toInt(),
      partName: json['partName'] as String,
      catalogNumber: json['catalogNumber'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCost: f(json['unitCost']) ?? 0.0,
      totalCost: f(json['totalCost']),
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
      supplierId: (json['supplierId'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      installationNotes: json['installationNotes'] as String?,
      createdDate: d(json['createdDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceHistoryId': serviceHistoryId,
        'partCatalogId': partCatalogId,
        'partName': partName,
        'catalogNumber': catalogNumber,
        'quantity': quantity,
        'unitCost': unitCost,
        'totalCost': totalCost,
        'warrantyMonths': warrantyMonths,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'installationNotes': installationNotes,
        'createdDate': createdDate?.toIso8601String(),
      };
}
