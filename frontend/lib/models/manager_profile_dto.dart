class ManagerProfileDto {
  final String fullName;
  final String? contactEmail;
  final String? contactPhone;

  ManagerProfileDto({
    required this.fullName,
    this.contactEmail,
    this.contactPhone,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
      };

  factory ManagerProfileDto.fromJson(Map<String, dynamic> json) {
    return ManagerProfileDto(
      fullName: json['fullName'] as String,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
    );
  }
}
