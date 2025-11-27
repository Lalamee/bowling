class MechanicCertificationDto {
  final int? certificationId;
  final String? title;
  final String? issuer;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final String? credentialUrl;
  final String? description;

  MechanicCertificationDto({
    this.certificationId,
    this.title,
    this.issuer,
    this.issueDate,
    this.expirationDate,
    this.credentialUrl,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'certificationId': certificationId,
        'title': title,
        'issuer': issuer,
        'issueDate': issueDate?.toIso8601String().split('T').first,
        'expirationDate': expirationDate?.toIso8601String().split('T').first,
        'credentialUrl': credentialUrl,
        'description': description,
      };

  factory MechanicCertificationDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return MechanicCertificationDto(
      certificationId: (json['certificationId'] as num?)?.toInt(),
      title: json['title'] as String?,
      issuer: json['issuer'] as String?,
      issueDate: parseDate(json['issueDate']),
      expirationDate: parseDate(json['expirationDate']),
      credentialUrl: json['credentialUrl'] as String?,
      description: json['description'] as String?,
    );
  }
}
