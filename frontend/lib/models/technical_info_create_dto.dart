class TechnicalInfoCreateDto {
  final int clubId;
  final String? equipmentType;
  final String? manufacturer;
  final String model;
  final String? serialNumber;
  final int? lanesCount;
  final int? productionYear;
  final int? conditionPercentage;
  final DateTime? purchaseDate;
  final DateTime? warrantyUntil;
  final String? status;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;

  TechnicalInfoCreateDto({
    required this.clubId,
    required this.model,
    this.equipmentType,
    this.manufacturer,
    this.serialNumber,
    this.lanesCount,
    this.productionYear,
    this.conditionPercentage,
    this.purchaseDate,
    this.warrantyUntil,
    this.status,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        if (equipmentType != null && equipmentType!.trim().isNotEmpty) 'equipmentType': equipmentType!.trim(),
        if (manufacturer != null && manufacturer!.trim().isNotEmpty) 'manufacturer': manufacturer!.trim(),
        'model': model.trim(),
        if (serialNumber != null && serialNumber!.trim().isNotEmpty) 'serialNumber': serialNumber!.trim(),
        if (lanesCount != null) 'lanesCount': lanesCount,
        if (productionYear != null) 'productionYear': productionYear,
        if (conditionPercentage != null) 'conditionPercentage': conditionPercentage,
        if (purchaseDate != null) 'purchaseDate': _formatDate(purchaseDate!),
        if (warrantyUntil != null) 'warrantyUntil': _formatDate(warrantyUntil!),
        if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
        if (lastMaintenanceDate != null) 'lastMaintenanceDate': _formatDate(lastMaintenanceDate!),
        if (nextMaintenanceDate != null) 'nextMaintenanceDate': _formatDate(nextMaintenanceDate!),
      };
}

String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
