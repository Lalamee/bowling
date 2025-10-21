class UserInfoDto {
  final int id;
  final String phone;
  final int? roleId;
  final int? accountTypeId;
  final String? roleName;
  final String? accountTypeName;
  final bool? isVerified;
  final DateTime? registrationDate;

  UserInfoDto({
    required this.id,
    required this.phone,
    this.roleId,
    this.accountTypeId,
    this.roleName,
    this.accountTypeName,
    this.isVerified,
    this.registrationDate,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return UserInfoDto(
      id: (json['id'] as num).toInt(),
      phone: json['phone'] as String,
      roleId: (json['roleId'] as num?)?.toInt(),
      accountTypeId: (json['accountTypeId'] as num?)?.toInt(),
      roleName: json['role']?.toString(),
      accountTypeName: json['accountType']?.toString(),
      isVerified: json['isVerified'] as bool?,
      registrationDate: parseDate(json['registrationDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'roleId': roleId,
        'accountTypeId': accountTypeId,
        'role': roleName,
        'accountType': accountTypeName,
        'isVerified': isVerified,
        'registrationDate': registrationDate?.toIso8601String(),
      };
}
