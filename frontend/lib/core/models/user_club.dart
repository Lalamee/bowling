class UserClub {
  final int id;
  final String name;
  final String? address;
  final String? lanes;
  final String? equipment;
  final String? phone;
  final String? email;
  final String? accessLevel;
  final DateTime? accessExpiresAt;
  final bool infoAccessRestricted;
  final bool isTemporary;

  const UserClub({
    required this.id,
    required this.name,
    this.address,
    this.lanes,
    this.equipment,
    this.phone,
    this.email,
    this.accessLevel,
    this.accessExpiresAt,
    this.infoAccessRestricted = false,
    this.isTemporary = false,
  });

  UserClub copyWith({
    String? name,
    String? address,
    String? lanes,
    String? equipment,
    String? phone,
    String? email,
    String? accessLevel,
    DateTime? accessExpiresAt,
    bool? infoAccessRestricted,
    bool? isTemporary,
  }) {
    return UserClub(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      lanes: lanes ?? this.lanes,
      equipment: equipment ?? this.equipment,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      accessLevel: accessLevel ?? this.accessLevel,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      infoAccessRestricted: infoAccessRestricted ?? this.infoAccessRestricted,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
