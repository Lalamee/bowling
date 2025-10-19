class RegisterUserDto {
  final String phone;
  final String password;
  final int roleId;
  final int accountTypeId;

  RegisterUserDto({
    required this.phone,
    required this.password,
    required this.roleId,
    required this.accountTypeId,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
        'roleId': roleId,
        'accountTypeId': accountTypeId,
      };

  factory RegisterUserDto.fromJson(Map<String, dynamic> json) {
    return RegisterUserDto(
      phone: json['phone'] as String,
      password: json['password'] as String,
      roleId: (json['roleId'] as num).toInt(),
      accountTypeId: (json['accountTypeId'] as num).toInt(),
    );
  }
}
