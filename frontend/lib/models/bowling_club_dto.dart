class BowlingClubDto {
  final String name;
  final String address;
  final int lanesCount;
  final String? contactPhone;
  final String? contactEmail;

  BowlingClubDto({
    required this.name,
    required this.address,
    required this.lanesCount,
    this.contactPhone,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lanesCount': lanesCount,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
      };

  factory BowlingClubDto.fromJson(Map<String, dynamic> json) {
    return BowlingClubDto(
      name: json['name'] as String,
      address: json['address'] as String,
      lanesCount: json['lanesCount'] is int
          ? json['lanesCount'] as int
          : int.tryParse(json['lanesCount']?.toString() ?? '0') ?? 0,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
    );
  }
}
