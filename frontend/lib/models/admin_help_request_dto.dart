class AdminHelpRequestDto {
  final int requestId;
  final int partId;
  final int? mechanicProfileId;
  final int? clubId;
  final int? laneNumber;
  final bool? helpRequested;
  final String? partStatus;
  final String? managerNotes;

  AdminHelpRequestDto({
    required this.requestId,
    required this.partId,
    this.mechanicProfileId,
    this.clubId,
    this.laneNumber,
    this.helpRequested,
    this.partStatus,
    this.managerNotes,
  });

  factory AdminHelpRequestDto.fromJson(Map<String, dynamic> json) {
    return AdminHelpRequestDto(
      requestId: (json['requestId'] as num).toInt(),
      partId: (json['partId'] as num).toInt(),
      mechanicProfileId: (json['mechanicProfileId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      helpRequested: json['helpRequested'] as bool?,
      partStatus: json['partStatus'] as String?,
      managerNotes: json['managerNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'partId': partId,
        'mechanicProfileId': mechanicProfileId,
        'clubId': clubId,
        'laneNumber': laneNumber,
        'helpRequested': helpRequested,
        'partStatus': partStatus,
        'managerNotes': managerNotes,
      };
}
