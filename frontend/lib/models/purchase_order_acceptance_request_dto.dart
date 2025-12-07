class PurchaseOrderAcceptanceRequestDto {
  final List<PartAcceptanceDto> parts;
  final String supplierInn;
  final String? supplierName;
  final String? supplierContactPerson;
  final String? supplierPhone;
  final String? supplierEmail;
  final bool? supplierVerified;

  PurchaseOrderAcceptanceRequestDto({
    required this.parts,
    required this.supplierInn,
    this.supplierName,
    this.supplierContactPerson,
    this.supplierPhone,
    this.supplierEmail,
    this.supplierVerified,
  });

  Map<String, dynamic> toJson() => {
        'parts': parts.map((e) => e.toJson()).toList(),
        'supplierInn': supplierInn,
        'supplierName': supplierName,
        'supplierContactPerson': supplierContactPerson,
        'supplierPhone': supplierPhone,
        'supplierEmail': supplierEmail,
        'supplierVerified': supplierVerified,
      };
}

class PartAcceptanceDto {
  final int partId;
  final String status;
  final int acceptedQuantity;
  final String? comment;
  final String? storageLocation;
  final String? shelfCode;
  final String? cellCode;
  final String? placementNotes;

  PartAcceptanceDto({
    required this.partId,
    required this.status,
    required this.acceptedQuantity,
    this.comment,
    this.storageLocation,
    this.shelfCode,
    this.cellCode,
    this.placementNotes,
  });

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'status': status,
        'acceptedQuantity': acceptedQuantity,
        'comment': comment,
        'storageLocation': storageLocation,
        'shelfCode': shelfCode,
        'cellCode': cellCode,
        'placementNotes': placementNotes,
      };
}
