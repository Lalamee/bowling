class ApproveRejectRequestDto {
  final String? managerNotes;
  final String? rejectionReason;

  ApproveRejectRequestDto({
    this.managerNotes,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() => {
        'managerNotes': managerNotes,
        'rejectionReason': rejectionReason,
      };

  factory ApproveRejectRequestDto.fromJson(Map<String, dynamic> json) {
    return ApproveRejectRequestDto(
      managerNotes: json['managerNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
