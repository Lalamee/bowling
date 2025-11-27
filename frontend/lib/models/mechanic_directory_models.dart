import 'mechanic_certification_dto.dart';
import 'mechanic_work_history_dto.dart';

enum MechanicGrade { junior, middle, senior, lead;
  static MechanicGrade? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'JUNIOR':
        return MechanicGrade.junior;
      case 'MIDDLE':
        return MechanicGrade.middle;
      case 'SENIOR':
        return MechanicGrade.senior;
      case 'LEAD':
        return MechanicGrade.lead;
    }
    return null;
  }

  String toApiValue() {
    return name.toUpperCase();
  }
}

enum AttestationDecisionStatus { pending, approved, rejected;
  static AttestationDecisionStatus? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return AttestationDecisionStatus.pending;
      case 'APPROVED':
        return AttestationDecisionStatus.approved;
      case 'REJECTED':
        return AttestationDecisionStatus.rejected;
    }
    return null;
  }

  String toApiValue() => name.toUpperCase();
}

class MechanicDirectoryItem {
  final int profileId;
  final String? fullName;
  final String? specialization;
  final double? rating;
  final String? status;
  final String? region;
  final List<String> clubs;
  final List<MechanicCertificationDto> certifications;

  MechanicDirectoryItem({
    required this.profileId,
    this.fullName,
    this.specialization,
    this.rating,
    this.status,
    this.region,
    this.clubs = const [],
    this.certifications = const [],
  });

  factory MechanicDirectoryItem.fromJson(Map<String, dynamic> json) {
    final clubsRaw = json['clubs'];
    final certsRaw = json['certifications'];
    return MechanicDirectoryItem(
      profileId: (json['profileId'] as num).toInt(),
      fullName: json['fullName'] as String?,
      specialization: json['specialization'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      status: json['status'] as String?,
      region: json['region'] as String?,
      clubs: clubsRaw is List ? clubsRaw.map((e) => e.toString()).toList() : const [],
      certifications: certsRaw is List
          ? certsRaw
              .whereType<Map>()
              .map((e) => MechanicCertificationDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

class MechanicDirectoryDetail {
  final int profileId;
  final int? userId;
  final String? fullName;
  final String? contactPhone;
  final String? specialization;
  final double? rating;
  final String? status;
  final String? region;
  final List<MechanicCertificationDto> certifications;
  final int? totalExperienceYears;
  final int? bowlingExperienceYears;
  final bool? isEntrepreneur;
  final bool? isDataVerified;
  final DateTime? verificationDate;
  final List<MechanicDirectoryItem> relatedClubs;
  final List<MechanicWorkHistoryDto> workHistory;
  final String? attestationStatus;

  MechanicDirectoryDetail({
    required this.profileId,
    this.userId,
    this.fullName,
    this.contactPhone,
    this.specialization,
    this.rating,
    this.status,
    this.region,
    this.certifications = const [],
    this.totalExperienceYears,
    this.bowlingExperienceYears,
    this.isEntrepreneur,
    this.isDataVerified,
    this.verificationDate,
    this.relatedClubs = const [],
    this.workHistory = const [],
    this.attestationStatus,
  });

  factory MechanicDirectoryDetail.fromJson(Map<String, dynamic> json) {
    final clubsRaw = json['relatedClubs'];
    final certsRaw = json['certifications'];
    final historyRaw = json['workHistory'];
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return MechanicDirectoryDetail(
      profileId: (json['profileId'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      specialization: json['specialization'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      status: json['status'] as String?,
      region: json['region'] as String?,
      certifications: certsRaw is List
          ? certsRaw
              .whereType<Map>()
              .map((e) => MechanicCertificationDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      totalExperienceYears: (json['totalExperienceYears'] as num?)?.toInt(),
      bowlingExperienceYears: (json['bowlingExperienceYears'] as num?)?.toInt(),
      isEntrepreneur: json['isEntrepreneur'] as bool?,
      isDataVerified: json['isDataVerified'] as bool?,
      verificationDate: parseDate(json['verificationDate']),
      relatedClubs: clubsRaw is List
          ? clubsRaw
              .whereType<Map>()
              .map((e) => MechanicDirectoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      workHistory: historyRaw is List
          ? historyRaw
              .whereType<Map>()
              .map((e) => MechanicWorkHistoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      attestationStatus: json['attestationStatus'] as String?,
    );
  }
}

class AttestationApplication {
  final int? id;
  final int? userId;
  final int? mechanicProfileId;
  final int? clubId;
  final AttestationDecisionStatus? status;
  final String? comment;
  final MechanicGrade? requestedGrade;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  AttestationApplication({
    this.id,
    this.userId,
    this.mechanicProfileId,
    this.clubId,
    this.status,
    this.comment,
    this.requestedGrade,
    this.submittedAt,
    this.updatedAt,
  });

  factory AttestationApplication.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return AttestationApplication(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      mechanicProfileId: (json['mechanicProfileId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      status: AttestationDecisionStatus.fromString(json['status'] as String?),
      comment: json['comment'] as String?,
      requestedGrade: MechanicGrade.fromString(json['requestedGrade'] as String?),
      submittedAt: parseDate(json['submittedAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mechanicProfileId': mechanicProfileId,
      'clubId': clubId,
      'status': status?.toApiValue(),
      'comment': comment,
      'requestedGrade': requestedGrade?.toApiValue(),
      'submittedAt': submittedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SpecialistCard {
  final int profileId;
  final int? userId;
  final String? fullName;
  final String? region;
  final int? specializationId;
  final String? skills;
  final String? advantages;
  final int? totalExperienceYears;
  final int? bowlingExperienceYears;
  final bool? isEntrepreneur;
  final double? rating;
  final MechanicGrade? attestedGrade;
  final String? accountType;
  final DateTime? verificationDate;
  final List<String> clubs;

  SpecialistCard({
    required this.profileId,
    this.userId,
    this.fullName,
    this.region,
    this.specializationId,
    this.skills,
    this.advantages,
    this.totalExperienceYears,
    this.bowlingExperienceYears,
    this.isEntrepreneur,
    this.rating,
    this.attestedGrade,
    this.accountType,
    this.verificationDate,
    this.clubs = const [],
  });

  factory SpecialistCard.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    final clubsRaw = json['clubs'];
    return SpecialistCard(
      profileId: (json['profileId'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'] as String?,
      region: json['region'] as String?,
      specializationId: (json['specializationId'] as num?)?.toInt(),
      skills: json['skills'] as String?,
      advantages: json['advantages'] as String?,
      totalExperienceYears: (json['totalExperienceYears'] as num?)?.toInt(),
      bowlingExperienceYears: (json['bowlingExperienceYears'] as num?)?.toInt(),
      isEntrepreneur: json['isEntrepreneur'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
      attestedGrade: MechanicGrade.fromString(json['attestedGrade'] as String?),
      accountType: json['accountType'] as String?,
      verificationDate: parseDate(json['verificationDate']),
      clubs: clubsRaw is List ? clubsRaw.map((e) => e.toString()).toList() : const [],
    );
  }
}

