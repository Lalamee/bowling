class PasswordChangeRequestDto {
  final String oldPassword;
  final String newPassword;

  PasswordChangeRequestDto({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

  factory PasswordChangeRequestDto.fromJson(Map<String, dynamic> json) {
    return PasswordChangeRequestDto(
      oldPassword: json['oldPassword'] as String,
      newPassword: json['newPassword'] as String,
    );
  }
}
