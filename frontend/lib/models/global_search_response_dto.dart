import 'part_dto.dart';

class GlobalSearchResponseDto {
  final List<PartDto> parts;
  final List<SearchMaintenanceRequestDto> maintenanceRequests;
  final List<SearchWorkLogDto> workLogs;
  final List<SearchClubDto> clubs;

  GlobalSearchResponseDto({
    required this.parts,
    required this.maintenanceRequests,
    required this.workLogs,
    required this.clubs,
  });

  factory GlobalSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final partsJson = json['parts'] as List<dynamic>? ?? const [];
    final requestsJson = json['maintenanceRequests'] as List<dynamic>? ?? const [];
    final workLogsJson = json['workLogs'] as List<dynamic>? ?? const [];
    final clubsJson = json['clubs'] as List<dynamic>? ?? const [];

    return GlobalSearchResponseDto(
      parts: partsJson
          .whereType<Map>()
          .map((e) => PartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      maintenanceRequests: requestsJson
          .whereType<Map>()
          .map((e) => SearchMaintenanceRequestDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      workLogs: workLogsJson
          .whereType<Map>()
          .map((e) => SearchWorkLogDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      clubs: clubsJson
          .whereType<Map>()
          .map((e) => SearchClubDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class SearchMaintenanceRequestDto {
  final int id;
  final String? status;
  final String? clubName;
  final int? laneNumber;
  final String? mechanicName;
  final DateTime? requestedAt;

  SearchMaintenanceRequestDto({
    required this.id,
    this.status,
    this.clubName,
    this.laneNumber,
    this.mechanicName,
    this.requestedAt,
  });

  factory SearchMaintenanceRequestDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return SearchMaintenanceRequestDto(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String?,
      clubName: json['clubName'] as String?,
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      mechanicName: json['mechanicName'] as String?,
      requestedAt: parseDate(json['requestedAt']),
    );
  }
}

class SearchWorkLogDto {
  final int id;
  final String? status;
  final String? workType;
  final String? clubName;
  final int? laneNumber;
  final String? mechanicName;
  final String? problemDescription;
  final DateTime? createdAt;

  SearchWorkLogDto({
    required this.id,
    this.status,
    this.workType,
    this.clubName,
    this.laneNumber,
    this.mechanicName,
    this.problemDescription,
    this.createdAt,
  });

  factory SearchWorkLogDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return SearchWorkLogDto(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String?,
      workType: json['workType'] as String?,
      clubName: json['clubName'] as String?,
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      mechanicName: json['mechanicName'] as String?,
      problemDescription: json['problemDescription'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }
}

class SearchClubDto {
  final int id;
  final String? name;
  final String? address;
  final bool? active;
  final bool? verified;

  SearchClubDto({
    required this.id,
    this.name,
    this.address,
    this.active,
    this.verified,
  });

  factory SearchClubDto.fromJson(Map<String, dynamic> json) {
    return SearchClubDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      active: json['active'] as bool?,
      verified: json['verified'] as bool?,
    );
  }
}
