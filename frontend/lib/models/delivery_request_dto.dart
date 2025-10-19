class DeliveryRequestDto {
  final DateTime? deliveryDate;
  final String? notes;

  DeliveryRequestDto({
    this.deliveryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (deliveryDate != null) 'deliveryDate': deliveryDate!.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
    };
  }

  factory DeliveryRequestDto.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestDto(
      deliveryDate: json['deliveryDate'] != null 
          ? DateTime.parse(json['deliveryDate']) 
          : null,
      notes: json['notes'],
    );
  }
}
