class AdminRegistrationApplicationDto {
  final int? userId;
  final int? profileId;
  final String? phone;
  final String? fullName;
  final String? role;
  final String? accountType;
  final String? applicationType;
  final String? status;
  final String? profileType;
  final bool? isActive;
  final bool? isVerified;
  final bool? isProfileVerified;
  final int? clubId;
  final String? clubName;
  final DateTime? submittedAt;
  final String? decisionComment;
  final Map<String, dynamic>? payload;

  const AdminRegistrationApplicationDto({
    this.userId,
    this.profileId,
    this.phone,
    this.fullName,
    this.role,
    this.accountType,
    this.applicationType,
    this.status,
    this.profileType,
    this.isActive,
    this.isVerified,
    this.isProfileVerified,
    this.clubId,
    this.clubName,
    this.submittedAt,
    this.decisionComment,
    this.payload,
  });

  factory AdminRegistrationApplicationDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool? asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
      return null;
    }

    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    DateTime? asDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
      return null;
    }

    return AdminRegistrationApplicationDto(
      userId: asInt(json['userId']),
      profileId: asInt(json['profileId']),
      phone: asString(json['phone']),
      fullName: asString(json['fullName']),
      role: asString(json['role']),
      accountType: asString(json['accountType']),
      applicationType: asString(json['applicationType'] ?? json['type']),
      status: asString(json['status'] ?? json['registrationStatus']),
      profileType: asString(json['profileType']),
      isActive: asBool(json['isActive']),
      isVerified: asBool(json['isVerified']),
      isProfileVerified: asBool(json['isProfileVerified']),
      clubId: asInt(json['clubId']),
      clubName: asString(json['clubName']),
      submittedAt: asDate(json['submittedAt'] ?? json['createdAt']),
      decisionComment: asString(json['decisionComment'] ?? json['rejectionReason']),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'profileId': profileId,
        'phone': phone,
        'fullName': fullName,
        'role': role,
        'accountType': accountType,
        'applicationType': applicationType,
        'status': status,
        'profileType': profileType,
        'isActive': isActive,
        'isVerified': isVerified,
        'isProfileVerified': isProfileVerified,
        'clubId': clubId,
        'clubName': clubName,
        'submittedAt': submittedAt?.toIso8601String(),
        'decisionComment': decisionComment,
        'payload': payload,
      };
}
