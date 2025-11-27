class HelpRequestDto {
  final List<int> partIds;
  final String? reason;

  HelpRequestDto({required this.partIds, this.reason});

  factory HelpRequestDto.fromJson(Map<String, dynamic> json) {
    return HelpRequestDto(
      partIds: (json['partIds'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'partIds': partIds,
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason,
      };
}

enum HelpResponseDecision { approved, reassigned, declined }

HelpResponseDecision? helpDecisionFromBackend(String? raw) {
  final normalized = raw?.trim().toUpperCase();
  switch (normalized) {
    case 'APPROVED':
      return HelpResponseDecision.approved;
    case 'REASSIGNED':
      return HelpResponseDecision.reassigned;
    case 'DECLINED':
      return HelpResponseDecision.declined;
  }
  return null;
}

String helpDecisionToBackend(HelpResponseDecision decision) {
  switch (decision) {
    case HelpResponseDecision.approved:
      return 'APPROVED';
    case HelpResponseDecision.reassigned:
      return 'REASSIGNED';
    case HelpResponseDecision.declined:
      return 'DECLINED';
  }
}

class HelpResponseDto {
  final List<int> partIds;
  final HelpResponseDecision decision;
  final int? reassignedMechanicId;
  final String? comment;

  HelpResponseDto({
    required this.partIds,
    required this.decision,
    this.reassignedMechanicId,
    this.comment,
  });

  factory HelpResponseDto.fromJson(Map<String, dynamic> json) {
    return HelpResponseDto(
      partIds: (json['partIds'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      decision: helpDecisionFromBackend(json['decision'] as String?) ??
          HelpResponseDecision.approved,
      reassignedMechanicId: (json['reassignedMechanicId'] as num?)?.toInt(),
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'partIds': partIds,
        'decision': helpDecisionToBackend(decision),
        if (reassignedMechanicId != null) 'reassignedMechanicId': reassignedMechanicId,
        if (comment != null && comment!.trim().isNotEmpty) 'comment': comment,
      };
}
