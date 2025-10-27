import 'package:flutter/foundation.dart';

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
    return GlobalSearchResponseDto(
      parts: _parseSection(
        json['parts'],
        'part',
        (map) => PartDto.fromJson(map),
      ),
      maintenanceRequests: _parseSection(
        json['maintenanceRequests'],
        'maintenance request',
        (map) => SearchMaintenanceRequestDto.fromJson(map),
      ),
      workLogs: _parseSection(
        json['workLogs'],
        'work log',
        (map) => SearchWorkLogDto.fromJson(map),
      ),
      clubs: _parseSection(
        json['clubs'],
        'club',
        (map) => SearchClubDto.fromJson(map),
      ),
    );
  }

  static List<T> _parseSection<T>(
    dynamic source,
    String sectionName,
    T? Function(Map<String, dynamic> map) parser,
  ) {
    if (source is! List) {
      return const [];
    }

    final result = <T>[];
    for (final entry in source) {
      if (entry is! Map) {
        continue;
      }

      try {
        final parsed = parser(Map<String, dynamic>.from(entry as Map));
        if (parsed != null) {
          result.add(parsed);
        }
      } catch (error, stackTrace) {
        _logParseError(sectionName, error, stackTrace);
      }
    }
    return result;
  }

  static void _logParseError(String section, Object error, StackTrace stackTrace) {
    assert(() {
      debugPrint('Failed to parse $section entry: $error');
      debugPrint(stackTrace.toString());
      return true;
    }());
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
    return SearchMaintenanceRequestDto(
      id: _parseRequiredInt(json['id'], 'id'),
      status: json['status'] as String?,
      clubName: json['clubName'] as String?,
      laneNumber: _parseOptionalInt(json['laneNumber']),
      mechanicName: json['mechanicName'] as String?,
      requestedAt: _parseOptionalDateTime(json['requestedAt']),
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
    return SearchWorkLogDto(
      id: _parseRequiredInt(json['id'], 'id'),
      status: json['status'] as String?,
      workType: json['workType'] as String?,
      clubName: json['clubName'] as String?,
      laneNumber: _parseOptionalInt(json['laneNumber']),
      mechanicName: json['mechanicName'] as String?,
      problemDescription: json['problemDescription'] as String?,
      createdAt: _parseOptionalDateTime(json['createdAt']),
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
      id: _parseRequiredInt(json['id'], 'id'),
      name: json['name'] as String?,
      address: json['address'] as String?,
      active: _parseOptionalBool(json['active']),
      verified: _parseOptionalBool(json['verified']),
    );
  }
}

int _parseRequiredInt(dynamic value, String fieldName) {
  final parsed = _parseOptionalInt(value);
  if (parsed == null) {
    throw FormatException('Missing or invalid $fieldName');
  }
  return parsed;
}

int? _parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

bool? _parseOptionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

DateTime? _parseOptionalDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
