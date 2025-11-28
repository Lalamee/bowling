class AdminRegistrationApplicationDto {
  final int? userId;
  final int? profileId;
  final String? phone;
  final String? fullName;
  final String? role;
  final String? accountType;
  final String? profileType;
  final bool? isActive;
  final bool? isVerified;
  final bool? isProfileVerified;
  final int? clubId;
  final String? clubName;
  final String? submittedAt;

  const AdminRegistrationApplicationDto({
    this.userId,
    this.profileId,
    this.phone,
    this.fullName,
    this.role,
    this.accountType,
    this.profileType,
    this.isActive,
    this.isVerified,
    this.isProfileVerified,
    this.clubId,
    this.clubName,
    this.submittedAt,
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

    return AdminRegistrationApplicationDto(
      userId: asInt(json['userId']),
      profileId: asInt(json['profileId']),
      phone: asString(json['phone']),
      fullName: asString(json['fullName']),
      role: asString(json['role']),
      accountType: asString(json['accountType']),
      profileType: asString(json['profileType']),
      isActive: asBool(json['isActive']),
      isVerified: asBool(json['isVerified']),
      isProfileVerified: asBool(json['isProfileVerified']),
      clubId: asInt(json['clubId']),
      clubName: asString(json['clubName']),
      submittedAt: asString(json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'profileId': profileId,
        'phone': phone,
        'fullName': fullName,
        'role': role,
        'accountType': accountType,
        'profileType': profileType,
        'isActive': isActive,
        'isVerified': isVerified,
        'isProfileVerified': isProfileVerified,
        'clubId': clubId,
        'clubName': clubName,
        'submittedAt': submittedAt,
      };
}
