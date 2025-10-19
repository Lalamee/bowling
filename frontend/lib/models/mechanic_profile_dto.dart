class MechanicProfileDto {
  final String fullName;
  final DateTime birthDate;
  final int? educationLevelId;
  final String? educationalInstitution;
  final int totalExperienceYears;
  final int bowlingExperienceYears;
  final bool isEntrepreneur;
  final int? specializationId;
  final String? skills;
  final String? advantages;
  final String? workPlaces;
  final String? workPeriods;

  MechanicProfileDto({
    required this.fullName,
    required this.birthDate,
    this.educationLevelId,
    this.educationalInstitution,
    required this.totalExperienceYears,
    required this.bowlingExperienceYears,
    this.isEntrepreneur = false,
    this.specializationId,
    this.skills,
    this.advantages,
    this.workPlaces,
    this.workPeriods,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'birthDate': birthDate.toIso8601String().split('T')[0], // LocalDate format
        'educationLevelId': educationLevelId,
        'educationalInstitution': educationalInstitution,
        'totalExperienceYears': totalExperienceYears,
        'bowlingExperienceYears': bowlingExperienceYears,
        'isEntrepreneur': isEntrepreneur,
        'specializationId': specializationId,
        'skills': skills,
        'advantages': advantages,
        'workPlaces': workPlaces,
        'workPeriods': workPeriods,
      };

  factory MechanicProfileDto.fromJson(Map<String, dynamic> json) {
    return MechanicProfileDto(
      fullName: json['fullName'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      educationLevelId: (json['educationLevelId'] as num?)?.toInt(),
      educationalInstitution: json['educationalInstitution'] as String?,
      totalExperienceYears: (json['totalExperienceYears'] as num).toInt(),
      bowlingExperienceYears: (json['bowlingExperienceYears'] as num).toInt(),
      isEntrepreneur: json['isEntrepreneur'] as bool? ?? false,
      specializationId: (json['specializationId'] as num?)?.toInt(),
      skills: json['skills'] as String?,
      advantages: json['advantages'] as String?,
      workPlaces: json['workPlaces'] as String?,
      workPeriods: json['workPeriods'] as String?,
    );
  }
}
