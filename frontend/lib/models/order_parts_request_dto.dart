class OrderPartsRequestDto {
  final String? notes;
  final List<OrderedPartDto>? parts;

  OrderPartsRequestDto({
    this.notes,
    this.parts,
  });

  Map<String, dynamic> toJson() {
    return {
      if (notes != null) 'notes': notes,
      if (parts != null) 'parts': parts!.map((p) => p.toJson()).toList(),
    };
  }

  factory OrderPartsRequestDto.fromJson(Map<String, dynamic> json) {
    return OrderPartsRequestDto(
      notes: json['notes'],
      parts: json['parts'] != null
          ? (json['parts'] as List).map((p) => OrderedPartDto.fromJson(p)).toList()
          : null,
    );
  }
}

class OrderedPartDto {
  final String catalogNumber;
  final int quantity;
  final String? notes;

  OrderedPartDto({
    required this.catalogNumber,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'catalogNumber': catalogNumber,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }

  factory OrderedPartDto.fromJson(Map<String, dynamic> json) {
    return OrderedPartDto(
      catalogNumber: json['catalogNumber'],
      quantity: json['quantity'],
      notes: json['notes'],
    );
  }
}
