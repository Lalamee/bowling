class OneCSyncStatusDto {
  final String? startedAt;
  final String? finishedAt;
  final bool success;
  final String? trigger;
  final String? message;
  final int imported;
  final int updated;
  final int skipped;

  const OneCSyncStatusDto({
    this.startedAt,
    this.finishedAt,
    required this.success,
    this.trigger,
    this.message,
    required this.imported,
    required this.updated,
    required this.skipped,
  });

  factory OneCSyncStatusDto.fromJson(Map<String, dynamic> json) {
    return OneCSyncStatusDto(
      startedAt: json['startedAt'] as String?,
      finishedAt: json['finishedAt'] as String?,
      success: json['success'] == true,
      trigger: json['trigger'] as String?,
      message: json['message'] as String?,
      imported: (json['imported'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    );
  }
}
