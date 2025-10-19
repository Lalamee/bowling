class RefreshTokenRequestDto {
  final String refreshToken;

  RefreshTokenRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequestDto(
      refreshToken: json['refreshToken'] as String,
    );
  }
}
