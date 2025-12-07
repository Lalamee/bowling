class AdminMechanicStatusChangeDto {
  final int? staffId;
  final int? userId;
  final int? mechanicProfileId;
  final int? clubId;
  final String? clubName;
  final String? role;
  final bool? isActive;
  final bool? infoAccessRestricted;

  const AdminMechanicStatusChangeDto({
    this.staffId,
    this.userId,
    this.mechanicProfileId,
    this.clubId,
    this.clubName,
    this.role,
    this.isActive,
    this.infoAccessRestricted,
  });

  factory AdminMechanicStatusChangeDto.fromJson(Map<String, dynamic> json) {
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

    return AdminMechanicStatusChangeDto(
      staffId: asInt(json['staffId']),
      userId: asInt(json['userId']),
      mechanicProfileId: asInt(json['mechanicProfileId']),
      clubId: asInt(json['clubId']),
      clubName: asString(json['clubName']),
      role: asString(json['role']),
      isActive: asBool(json['isActive']),
      infoAccessRestricted: asBool(json['infoAccessRestricted']),
    );
  }

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'userId': userId,
        'mechanicProfileId': mechanicProfileId,
        'clubId': clubId,
        'clubName': clubName,
        'role': role,
        'isActive': isActive,
        'infoAccessRestricted': infoAccessRestricted,
      };
}

