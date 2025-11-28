class AdminAccountUpdateDto {
  final String? accountTypeName;
  final String? accessLevelName;

  const AdminAccountUpdateDto({
    this.accountTypeName,
    this.accessLevelName,
  });

  Map<String, dynamic> toJson() => {
        'accountTypeName': accountTypeName,
        'accessLevelName': accessLevelName,
      };
}
