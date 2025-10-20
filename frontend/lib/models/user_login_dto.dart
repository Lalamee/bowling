class UserLoginDto {
  final String phone;
  final String password;

  UserLoginDto({
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
      };

  factory UserLoginDto.fromJson(Map<String, dynamic> json) {
    return UserLoginDto(
      phone: json['phone'] as String,
      password: json['password'] as String,
    );
  }
}
