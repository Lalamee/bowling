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
  }) : clubs = _prepareClubs(clubs, clubName);

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
    final nextClubName = clubName ?? this.clubName;

    return MechanicProfile(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      clubName: nextClubName,
      address: address ?? this.address,
      workplaceVerified: workplaceVerified ?? this.workplaceVerified,
      birthDate: birthDate ?? this.birthDate,
      status: status ?? this.status,
      clubs: clubs ?? _prepareClubs(this.clubs, nextClubName),
    );
  }

  static List<String> _prepareClubs(List<String>? clubs, String clubName) {
    final result = <String>[];
    final seen = <String>{};

    void add(String? value, {bool prioritize = false}) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      if (seen.contains(trimmed)) {
        if (prioritize) {
          result
            ..remove(trimmed)
            ..insert(0, trimmed);
        }
        return;
      }
      if (prioritize) {
        result.insert(0, trimmed);
      } else {
        result.add(trimmed);
      }
      seen.add(trimmed);
    }

    add(clubName, prioritize: true);
    if (clubs != null) {
      for (final value in clubs) {
        add(value);
      }
    }
    return result;
  }
}
