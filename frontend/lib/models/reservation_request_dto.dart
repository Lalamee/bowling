class ReservationRequestDto {
  final int partId;
  final int quantity;
  final int maintenanceRequestId;

  ReservationRequestDto({
    required this.partId,
    required this.quantity,
    required this.maintenanceRequestId,
  });

  factory ReservationRequestDto.fromJson(Map<String, dynamic> json) {
    return ReservationRequestDto(
      partId: (json['partId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      maintenanceRequestId: (json['maintenanceRequestId'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'quantity': quantity,
        'maintenanceRequestId': maintenanceRequestId,
      };
}
