class ClubSummaryDto {
  final int id;
  final String name;
  final String? address;
  final int? lanesCount;
  final String? contactPhone;
  final String? contactEmail;

  ClubSummaryDto({
    required this.id,
    required this.name,
    this.address,
    this.lanesCount,
    this.contactPhone,
    this.contactEmail,
  });

  factory ClubSummaryDto.fromJson(Map<String, dynamic> json) {
    return ClubSummaryDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      lanesCount: (json['lanesCount'] as num?)?.toInt(),
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
    );
  }
}
