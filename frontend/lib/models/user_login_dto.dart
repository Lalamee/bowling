class UserLoginDto {
  final String identifier;
  final String password;

  UserLoginDto({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };

  factory UserLoginDto.fromJson(Map<String, dynamic> json) {
    return UserLoginDto(
      identifier: json['identifier'] as String,
      password: json['password'] as String,
    );
  }
}
