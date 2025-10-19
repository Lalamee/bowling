class PartDto {
  final int id;
  final String? officialNameEn;
  final String? officialNameRu;
  final String? commonName;
  final String? description;
  final String catalogNumber;
  final int? quantity;
  final String? location;

  PartDto({
    required this.id,
    this.officialNameEn,
    this.officialNameRu,
    this.commonName,
    this.description,
    required this.catalogNumber,
    this.quantity,
    this.location,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) {
    return PartDto(
      id: (json['id'] as num).toInt(),
      officialNameEn: json['officialNameEn'] as String?,
      officialNameRu: json['officialNameRu'] as String?,
      commonName: json['commonName'] as String?,
      description: json['description'] as String?,
      catalogNumber: json['catalogNumber'] as String,
      quantity: (json['quantity'] as num?)?.toInt(),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'officialNameEn': officialNameEn,
        'officialNameRu': officialNameRu,
        'commonName': commonName,
        'description': description,
        'catalogNumber': catalogNumber,
        'quantity': quantity,
        'location': location,
      };
}
