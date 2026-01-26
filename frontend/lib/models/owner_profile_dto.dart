class OwnerProfileDto {
  final String inn;
  final String address;
  final String? legalName;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;

  OwnerProfileDto({
    required this.inn,
    required this.address,
    this.legalName,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() => {
        'inn': inn,
        'address': address,
        'legalName': legalName,
        'contactPerson': contactPerson,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
      };

  factory OwnerProfileDto.fromJson(Map<String, dynamic> json) {
    return OwnerProfileDto(
      inn: json['inn'] as String,
      address: json['address'] as String? ?? '',
      legalName: json['legalName'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
    );
  }
}
