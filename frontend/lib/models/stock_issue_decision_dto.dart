class StockIssueDecisionDto {
  final String? managerNotes;
  final List<PartDecisionDto> partDecisions;

  StockIssueDecisionDto({this.managerNotes, required this.partDecisions});

  Map<String, dynamic> toJson() => {
        'managerNotes': managerNotes,
        'partDecisions': partDecisions.map((e) => e.toJson()).toList(),
      };
}

class PartDecisionDto {
  final int partId;
  final int approvedQuantity;
  final String? managerComment;

  PartDecisionDto({required this.partId, required this.approvedQuantity, this.managerComment});

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'approvedQuantity': approvedQuantity,
        'managerComment': managerComment,
      };
}
