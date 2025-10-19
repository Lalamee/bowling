class WorkLogStatusHistoryDto {
  final int? historyId;
  final int? workLogId;
  final String? previousStatus;
  final String? newStatus;
  final DateTime? changedDate;
  final int? changedByUserId;
  final String? changedByUserName;
  final String? reason;
  final String? additionalNotes;

  WorkLogStatusHistoryDto({
    this.historyId,
    this.workLogId,
    this.previousStatus,
    this.newStatus,
    this.changedDate,
    this.changedByUserId,
    this.changedByUserName,
    this.reason,
    this.additionalNotes,
  });

  factory WorkLogStatusHistoryDto.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return WorkLogStatusHistoryDto(
      historyId: (json['historyId'] as num?)?.toInt(),
      workLogId: (json['workLogId'] as num?)?.toInt(),
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String?,
      changedDate: d(json['changedDate']),
      changedByUserId: (json['changedByUserId'] as num?)?.toInt(),
      changedByUserName: json['changedByUserName'] as String?,
      reason: json['reason'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'historyId': historyId,
        'workLogId': workLogId,
        'previousStatus': previousStatus,
        'newStatus': newStatus,
        'changedDate': changedDate?.toIso8601String(),
        'changedByUserId': changedByUserId,
        'changedByUserName': changedByUserName,
        'reason': reason,
        'additionalNotes': additionalNotes,
      };
}
