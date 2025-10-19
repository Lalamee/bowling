class OrderPartsRequestDto {
  final String? notes;
  final List<OrderPartItemDto> items;

  OrderPartsRequestDto({
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((p) => p.toJson()).toList(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory OrderPartsRequestDto.fromJson(Map<String, dynamic> json) {
    return OrderPartsRequestDto(
      notes: json['notes'] as String?,
      items: (json['items'] as List? ?? [])
          .map((p) => OrderPartItemDto.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }
}

class OrderPartItemDto {
  final int partId;
  final int supplierId;

  OrderPartItemDto({
    required this.partId,
    required this.supplierId,
  });

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'supplierId': supplierId,
      };

  factory OrderPartItemDto.fromJson(Map<String, dynamic> json) => OrderPartItemDto(
        partId: (json['partId'] as num).toInt(),
        supplierId: (json['supplierId'] as num).toInt(),
      );
}
