class PurchaseOrderAcceptanceRequestDto {
  final List<PartAcceptanceDto> parts;

  PurchaseOrderAcceptanceRequestDto({required this.parts});

  Map<String, dynamic> toJson() => {
        'parts': parts.map((e) => e.toJson()).toList(),
      };
}

class PartAcceptanceDto {
  final int partId;
  final String status;
  final int acceptedQuantity;
  final String? comment;

  PartAcceptanceDto({
    required this.partId,
    required this.status,
    required this.acceptedQuantity,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'status': status,
        'acceptedQuantity': acceptedQuantity,
        'comment': comment,
      };
}
