class WorkLogSearchDto {
  int? clubId;
  int? laneNumber;
  int? mechanicId;
  int? equipmentId;
  String? status;
  String? workType;
  int? priority;
  DateTime? startDate;
  DateTime? endDate;
  bool? completedOnly;
  bool? activeOnly;
  String? keyword;
  bool? includeManualEdits;
  int page;
  int size;
  String sortBy;
  String sortDirection;

  WorkLogSearchDto({
    this.clubId,
    this.laneNumber,
    this.mechanicId,
    this.equipmentId,
    this.status,
    this.workType,
    this.priority,
    this.startDate,
    this.endDate,
    this.completedOnly,
    this.activeOnly,
    this.keyword,
    this.includeManualEdits,
    this.page = 0,
    this.size = 20,
    this.sortBy = 'createdDate',
    this.sortDirection = 'DESC',
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'laneNumber': laneNumber,
        'mechanicId': mechanicId,
        'equipmentId': equipmentId,
        'status': status,
        'workType': workType,
        'priority': priority,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'completedOnly': completedOnly,
        'activeOnly': activeOnly,
        'keyword': keyword,
        'includeManualEdits': includeManualEdits,
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      };
}
