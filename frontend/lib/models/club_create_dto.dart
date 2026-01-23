class ClubCreateDto {
  final String name;
  final String address;
  final int? lanesCount;
  final String? contactPhone;
  final String? contactEmail;

  ClubCreateDto({
    required this.name,
    required this.address,
    this.lanesCount,
    this.contactPhone,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'lanesCount': lanesCount,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
    };
  }
}
