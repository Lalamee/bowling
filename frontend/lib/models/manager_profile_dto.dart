class ManagerProfileDto {
  final String fullName;
  final String? contactEmail;
  final String? contactPhone;
  final int? clubId;

  ManagerProfileDto({
    required this.fullName,
    this.contactEmail,
    this.contactPhone,
    this.clubId,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'clubId': clubId,
      };

  factory ManagerProfileDto.fromJson(Map<String, dynamic> json) {
    return ManagerProfileDto(
      fullName: json['fullName'] as String,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      clubId: json['clubId'] as int?,
    );
  }
}
