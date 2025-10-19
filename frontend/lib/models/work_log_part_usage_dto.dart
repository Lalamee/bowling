class WorkLogPartUsageDto {
  final int? usageId;
  final int? workLogId;
  final int? partCatalogId;
  final String partName;
  final String catalogNumber;
  final int quantityUsed;
  final double unitCost;
  final double? totalCost;
  final String sourcedFrom;
  final int? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final int? warrantyMonths;
  final DateTime? installedDate;
  final String? notes;
  final DateTime? createdDate;
  final int? createdBy;
  final String? createdByName;

  WorkLogPartUsageDto({
    this.usageId,
    this.workLogId,
    this.partCatalogId,
    required this.partName,
    required this.catalogNumber,
    required this.quantityUsed,
    required this.unitCost,
    this.totalCost,
    required this.sourcedFrom,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.warrantyMonths,
    this.installedDate,
    this.notes,
    this.createdDate,
    this.createdBy,
    this.createdByName,
  });

  factory WorkLogPartUsageDto.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    return WorkLogPartUsageDto(
      usageId: (json['usageId'] as num?)?.toInt(),
      workLogId: (json['workLogId'] as num?)?.toInt(),
      partCatalogId: (json['partCatalogId'] as num?)?.toInt(),
      partName: json['partName'] as String,
      catalogNumber: json['catalogNumber'] as String,
      quantityUsed: (json['quantityUsed'] as num).toInt(),
      unitCost: f(json['unitCost']) ?? 0.0,
      totalCost: f(json['totalCost']),
      sourcedFrom: json['sourcedFrom'] as String,
      supplierId: (json['supplierId'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
      installedDate: d(json['installedDate']),
      notes: json['notes'] as String?,
      createdDate: d(json['createdDate']),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdByName: json['createdByName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'usageId': usageId,
        'workLogId': workLogId,
        'partCatalogId': partCatalogId,
        'partName': partName,
        'catalogNumber': catalogNumber,
        'quantityUsed': quantityUsed,
        'unitCost': unitCost,
        'totalCost': totalCost,
        'sourcedFrom': sourcedFrom,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'invoiceNumber': invoiceNumber,
        'warrantyMonths': warrantyMonths,
        'installedDate': installedDate?.toIso8601String(),
        'notes': notes,
        'createdDate': createdDate?.toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
      };
}
