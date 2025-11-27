class FreeMechanicApplicationResponseDto {
  final int? applicationId;
  final int? userId;
  final int? mechanicProfileId;
  final String? phone;
  final String? fullName;
  final String? status;
  final String? comment;
  final String? accountType;
  final bool? isActive;
  final bool? isVerified;
  final bool? isProfileVerified;
  final DateTime? profileCreatedAt;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  FreeMechanicApplicationResponseDto({
    this.applicationId,
    this.userId,
    this.mechanicProfileId,
    this.phone,
    this.fullName,
    this.status,
    this.comment,
    this.accountType,
    this.isActive,
    this.isVerified,
    this.isProfileVerified,
    this.profileCreatedAt,
    this.submittedAt,
    this.updatedAt,
  });

  factory FreeMechanicApplicationResponseDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;
    return FreeMechanicApplicationResponseDto(
      applicationId: (json['applicationId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      mechanicProfileId: (json['mechanicProfileId'] as num?)?.toInt(),
      phone: json['phone'] as String?,
      fullName: json['fullName'] as String?,
      status: json['status']?.toString(),
      comment: json['comment'] as String?,
      accountType: json['accountType']?.toString(),
      isActive: json['isActive'] as bool?,
      isVerified: json['isVerified'] as bool?,
      isProfileVerified: json['isProfileVerified'] as bool?,
      profileCreatedAt: parseDate(json['profileCreatedAt']),
      submittedAt: parseDate(json['submittedAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'userId': userId,
        'mechanicProfileId': mechanicProfileId,
        'phone': phone,
        'fullName': fullName,
        'status': status,
        'comment': comment,
        'accountType': accountType,
        'isActive': isActive,
        'isVerified': isVerified,
        'isProfileVerified': isProfileVerified,
        'profileCreatedAt': profileCreatedAt?.toIso8601String(),
        'submittedAt': submittedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
