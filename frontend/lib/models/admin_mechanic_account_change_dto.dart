class AdminMechanicAccountChangeDto {
  final String? accountTypeName;
  final String? accessLevelName;
  final int? clubId;
  final bool? attachToClub;

  const AdminMechanicAccountChangeDto({
    this.accountTypeName,
    this.accessLevelName,
    this.clubId,
    this.attachToClub,
  });

  Map<String, dynamic> toJson() => {
        'accountTypeName': accountTypeName,
        'accessLevelName': accessLevelName,
        'clubId': clubId,
        'attachToClub': attachToClub,
      };
}

