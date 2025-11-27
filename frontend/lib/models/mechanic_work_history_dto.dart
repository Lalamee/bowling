class MechanicWorkHistoryDto {
  final int? historyId;
  final String? organization;
  final String? position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  MechanicWorkHistoryDto({
    this.historyId,
    this.organization,
    this.position,
    this.startDate,
    this.endDate,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'historyId': historyId,
        'organization': organization,
        'position': position,
        'startDate': startDate?.toIso8601String().split('T').first,
        'endDate': endDate?.toIso8601String().split('T').first,
        'description': description,
      };

  factory MechanicWorkHistoryDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        (value is String && value.isNotEmpty) ? DateTime.tryParse(value) : null;

    return MechanicWorkHistoryDto(
      historyId: (json['historyId'] as num?)?.toInt(),
      organization: json['organization'] as String?,
      position: json['position'] as String?,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      description: json['description'] as String?,
    );
  }
}
