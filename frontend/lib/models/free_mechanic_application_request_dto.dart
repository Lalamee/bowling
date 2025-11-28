import 'mechanic_certification_dto.dart';
import 'mechanic_work_history_dto.dart';

class FreeMechanicApplicationRequestDto {
  final String phone;
  final String password;
  final String fullName;
  final DateTime birthDate;
  final int? educationLevelId;
  final String? educationalInstitution;
  final int totalExperienceYears;
  final int bowlingExperienceYears;
  final bool isEntrepreneur;
  final int? specializationId;
  final String region;
  final String? skills;
  final String? advantages;
  final List<MechanicCertificationDto> certifications;
  final List<MechanicWorkHistoryDto> workHistory;

  FreeMechanicApplicationRequestDto({
    required this.phone,
    required this.password,
    required this.fullName,
    required this.birthDate,
    this.educationLevelId,
    this.educationalInstitution,
    required this.totalExperienceYears,
    required this.bowlingExperienceYears,
    required this.isEntrepreneur,
    this.specializationId,
    required this.region,
    this.skills,
    this.advantages,
    this.certifications = const [],
    this.workHistory = const [],
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        'birthDate': birthDate.toIso8601String().split('T').first,
        'educationLevelId': educationLevelId,
        'educationalInstitution': educationalInstitution,
        'totalExperienceYears': totalExperienceYears,
        'bowlingExperienceYears': bowlingExperienceYears,
        'isEntrepreneur': isEntrepreneur,
        'specializationId': specializationId,
        'region': region,
        'skills': skills,
        'advantages': advantages,
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'workHistory': workHistory.map((e) => e.toJson()).toList(),
      };
}
