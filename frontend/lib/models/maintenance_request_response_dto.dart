class MaintenanceRequestResponseDto {
  final int requestId;
  final int? clubId;
  final String? clubName;
  final int? laneNumber;
  final int? mechanicId;
  final String? mechanicName;
  final DateTime? requestDate;
  final DateTime? completionDate;
  final String? status;
  final String? managerNotes;
  final DateTime? managerDecisionDate;
  final String? verificationStatus;
  final List<RequestPartResponseDto> requestedParts;

  MaintenanceRequestResponseDto({
    required this.requestId,
    this.clubId,
    this.clubName,
    this.laneNumber,
    this.mechanicId,
    this.mechanicName,
    this.requestDate,
    this.completionDate,
    this.status,
    this.managerNotes,
    this.managerDecisionDate,
    this.verificationStatus,
    required this.requestedParts,
  });

  factory MaintenanceRequestResponseDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return MaintenanceRequestResponseDto(
      requestId: (json['requestId'] as num).toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      clubName: json['clubName'] as String?,
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      mechanicId: (json['mechanicId'] as num?)?.toInt(),
      mechanicName: json['mechanicName'] as String?,
      requestDate: _d(json['requestDate']),
      completionDate: _d(json['completionDate']),
      status: json['status'] as String?,
      managerNotes: json['managerNotes'] as String?,
      managerDecisionDate: _d(json['managerDecisionDate']),
      verificationStatus: json['verificationStatus'] as String?,
      requestedParts: (json['requestedParts'] as List<dynamic>? ?? [])
          .map((e) => RequestPartResponseDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'clubId': clubId,
        'clubName': clubName,
        'laneNumber': laneNumber,
        'mechanicId': mechanicId,
        'mechanicName': mechanicName,
        'requestDate': requestDate?.toIso8601String(),
        'completionDate': completionDate?.toIso8601String(),
        'status': status,
        'managerNotes': managerNotes,
        'managerDecisionDate': managerDecisionDate?.toIso8601String(),
        'verificationStatus': verificationStatus,
        'requestedParts': requestedParts.map((e) => e.toJson()).toList(),
      };
}

class RequestPartResponseDto {
  final int partId;
  final String? catalogNumber;
  final String? partName;
  final int? quantity;
  final int? inventoryId;
  final int? catalogId;
  final int? warehouseId;
  final String? inventoryLocation;
  final String? status;
  final String? rejectionReason;
  final int? supplierId;
  final String? supplierName;
  final DateTime? orderDate;
  final DateTime? deliveryDate;
  final DateTime? issueDate;
  final bool? available;

  RequestPartResponseDto({
    required this.partId,
    this.catalogNumber,
    this.partName,
    this.quantity,
    this.inventoryId,
    this.catalogId,
    this.warehouseId,
    this.inventoryLocation,
    this.status,
    this.rejectionReason,
    this.supplierId,
    this.supplierName,
    this.orderDate,
    this.deliveryDate,
    this.issueDate,
    this.available,
  });

  factory RequestPartResponseDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return RequestPartResponseDto(
      partId: (json['partId'] as num).toInt(),
      catalogNumber: json['catalogNumber'] as String?,
      partName: json['partName'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      inventoryId: (json['inventoryId'] as num?)?.toInt(),
      catalogId: (json['catalogId'] as num?)?.toInt(),
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      inventoryLocation: json['inventoryLocation'] as String?,
      status: json['status'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      supplierId: (json['supplierId'] as num?)?.toInt(),
      supplierName: json['supplierName'] as String?,
      orderDate: _d(json['orderDate']),
      deliveryDate: _d(json['deliveryDate']),
      issueDate: _d(json['issueDate']),
      available: json['available'] is bool ? json['available'] as bool :
          (json['available'] is num ? (json['available'] as num) != 0 : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'catalogNumber': catalogNumber,
        'partName': partName,
        'quantity': quantity,
        'inventoryId': inventoryId,
        'catalogId': catalogId,
        'warehouseId': warehouseId,
        'inventoryLocation': inventoryLocation,
        'status': status,
        'rejectionReason': rejectionReason,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'orderDate': orderDate?.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'issueDate': issueDate?.toIso8601String(),
        'available': available,
      };
}
