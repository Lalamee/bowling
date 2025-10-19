class IssueRequestDto {
  final List<int> partIds;
  final DateTime? issueDate;
  final String? issuedTo;
  final String? notes;

  IssueRequestDto({
    required this.partIds,
    this.issueDate,
    this.issuedTo,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'partIds': partIds,
      if (issueDate != null) 'issueDate': issueDate!.toIso8601String(),
      if (issuedTo != null && issuedTo!.isNotEmpty) 'issuedTo': issuedTo,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory IssueRequestDto.fromJson(Map<String, dynamic> json) {
    return IssueRequestDto(
      partIds: (json['partIds'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate'].toString()) : null,
      issuedTo: json['issuedTo'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
