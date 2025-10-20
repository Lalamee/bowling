class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final LoginUserDto user;

  LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      user: LoginUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'user': user.toJson(),
      };
}

class LoginUserDto {
  final int id;
  final String? role;
  final String? name;
  final String? email;
  final String? phone;

  LoginUserDto({
    required this.id,
    this.role,
    this.name,
    this.email,
    this.phone,
  });

  factory LoginUserDto.fromJson(Map<String, dynamic> json) {
    return LoginUserDto(
      id: (json['id'] as num).toInt(),
      role: json['role'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (role != null) 'role': role,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}
