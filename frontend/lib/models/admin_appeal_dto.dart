class AdminAppealDto {
  final String? id;
  final String? type;
  final String? message;
  final int? requestId;
  final int? mechanicId;
  final int? clubId;
  final List<int>? partIds;
  final Map<String, dynamic>? payload;
  final DateTime? createdAt;

  const AdminAppealDto({
    this.id,
    this.type,
    this.message,
    this.requestId,
    this.mechanicId,
    this.clubId,
    this.partIds,
    this.payload,
    this.createdAt,
  });

  factory AdminAppealDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<int>? asIntList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => asInt(e))
            .where((e) => e != null)
            .map((e) => e!)
            .toList();
      }
      return null;
    }

    DateTime? asDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
      return null;
    }

    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    return AdminAppealDto(
      id: asString(json['id']),
      type: asString(json['type']),
      message: asString(json['message']),
      requestId: asInt(json['requestId']),
      mechanicId: asInt(json['mechanicId']),
      clubId: asInt(json['clubId']),
      partIds: asIntList(json['partIds']),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      createdAt: asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'requestId': requestId,
        'mechanicId': mechanicId,
        'clubId': clubId,
        'partIds': partIds,
        'payload': payload,
        'createdAt': createdAt?.toIso8601String(),
      };
}

