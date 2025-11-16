class MechanicDirectoryItem {
  final int profileId;
  final String? fullName;
  final String? specialization;
  final double? rating;
  final String? status;
  final String? region; // TODO: заменить реальным полем региона из анкеты
  final List<String> clubs;
  final List<String> certifications; // TODO: заменить моделью сертификатов

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
      clubs: clubsRaw is List ? clubsRaw.cast<String>() : const [],
      certifications: certsRaw is List ? certsRaw.cast<String>() : const [],
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
  final String? region; // TODO: заменить реальным полем региона из анкеты
  final List<String> certifications; // TODO: заменить моделью сертификатов
  final int? totalExperienceYears;
  final int? bowlingExperienceYears;
  final bool? isEntrepreneur;
  final bool? isDataVerified;
  final String? verificationDate;
  final List<MechanicDirectoryItem> relatedClubs;
  final String? workPlaces;
  final String? workPeriods;
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
    this.workPlaces,
    this.workPeriods,
    this.attestationStatus,
  });

  factory MechanicDirectoryDetail.fromJson(Map<String, dynamic> json) {
    final clubsRaw = json['relatedClubs'];
    final certsRaw = json['certifications'];
    return MechanicDirectoryDetail(
      profileId: (json['profileId'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      fullName: json['fullName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      specialization: json['specialization'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      status: json['status'] as String?,
      region: json['region'] as String?,
      certifications: certsRaw is List ? certsRaw.cast<String>() : const [],
      totalExperienceYears: (json['totalExperienceYears'] as num?)?.toInt(),
      bowlingExperienceYears: (json['bowlingExperienceYears'] as num?)?.toInt(),
      isEntrepreneur: json['isEntrepreneur'] as bool?,
      isDataVerified: json['isDataVerified'] as bool?,
      verificationDate: json['verificationDate'] as String?,
      relatedClubs: clubsRaw is List
          ? clubsRaw
              .whereType<Map>()
              .map((e) => MechanicDirectoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      workPlaces: json['workPlaces'] as String?,
      workPeriods: json['workPeriods'] as String?,
      attestationStatus: json['attestationStatus'] as String?,
    );
  }
}

class AttestationApplication {
  final int? id;
  final int? userId;
  final int? mechanicProfileId;
  final int? clubId;
  final String? status;
  final String? comment;
  final String? requestedGrade;
  final String? submittedAt;
  final String? updatedAt;

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
    return AttestationApplication(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      mechanicProfileId: (json['mechanicProfileId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      status: json['status'] as String?,
      comment: json['comment'] as String?,
      requestedGrade: json['requestedGrade'] as String?,
      submittedAt: json['submittedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mechanicProfileId': mechanicProfileId,
      'clubId': clubId,
      'status': status,
      'comment': comment,
      'requestedGrade': requestedGrade,
      'submittedAt': submittedAt,
      'updatedAt': updatedAt,
    };
  }
}

