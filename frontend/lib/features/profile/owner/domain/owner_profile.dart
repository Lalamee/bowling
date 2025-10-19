class OwnerProfile {
  final String fullName;
  final String phone;
  final String clubName;
  final List<String> clubs;
  final String address;
  final bool workplaceVerified;
  final DateTime birthDate;
  final String status;

  OwnerProfile({
    required this.fullName,
    required this.phone,
    required this.clubName,
    required this.clubs,
    required this.address,
    required this.workplaceVerified,
    required this.birthDate,
    required this.status,
  });

  OwnerProfile copyWith({
    String? fullName,
    String? phone,
    String? clubName,
    List<String>? clubs,
    String? address,
    bool? workplaceVerified,
    DateTime? birthDate,
    String? status,
  }) {
    return OwnerProfile(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      clubName: clubName ?? this.clubName,
      clubs: clubs ?? this.clubs,
      address: address ?? this.address,
      workplaceVerified: workplaceVerified ?? this.workplaceVerified,
      birthDate: birthDate ?? this.birthDate,
      status: status ?? this.status,
    );
  }
}
