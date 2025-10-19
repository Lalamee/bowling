class MechanicProfile {
  String fullName;
  String phone;
  String clubName; 
  List<String> clubs;
  String address;
  bool workplaceVerified;
  DateTime birthDate;

  final String status;

  MechanicProfile({
    required this.fullName,
    required this.phone,
    required this.clubName,
    required this.address,
    required this.workplaceVerified,
    required this.birthDate,
    required this.status,
    List<String>? clubs,
  }) : clubs = (clubs == null || clubs.isEmpty)
            ? [clubName]
            : clubs;

  MechanicProfile copyWith({
    String? fullName,
    String? phone,
    String? clubName,
    List<String>? clubs,
    String? address,
    bool? workplaceVerified,
    DateTime? birthDate,
    String? status,
  }) {
    final nextClubs = clubs ??
        (clubName != null
            ? [clubName, ...this.clubs.skip(1)]
            : this.clubs);

    return MechanicProfile(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      clubName: clubName ?? this.clubName,
      address: address ?? this.address,
      workplaceVerified: workplaceVerified ?? this.workplaceVerified,
      birthDate: birthDate ?? this.birthDate,
      status: status ?? this.status,
      clubs: nextClubs,
    );
  }
}
