class DeliveryRequestDto {
  final List<int> partIds;
  final DateTime? deliveryDate;
  final String? notes;

  DeliveryRequestDto({
    required this.partIds,
    this.deliveryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'partIds': partIds,
      if (deliveryDate != null) 'deliveryDate': deliveryDate!.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory DeliveryRequestDto.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestDto(
      partIds: (json['partIds'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
      deliveryDate:
          json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate'].toString()) : null,
      notes: json['notes'] as String?,
    );
  }
}
