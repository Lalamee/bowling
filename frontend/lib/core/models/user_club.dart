class UserClub {
  final int id;
  final String name;
  final String? address;
  final String? lanes;
  final String? equipment;
  final String? phone;
  final String? email;

  const UserClub({
    required this.id,
    required this.name,
    this.address,
    this.lanes,
    this.equipment,
    this.phone,
    this.email,
  });

  UserClub copyWith({
    String? name,
    String? address,
    String? lanes,
    String? equipment,
    String? phone,
    String? email,
  }) {
    return UserClub(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      lanes: lanes ?? this.lanes,
      equipment: equipment ?? this.equipment,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
