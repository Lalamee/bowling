class IssueRequestDto {
  final DateTime? issueDate;
  final String? issuedTo;
  final String? notes;

  IssueRequestDto({
    this.issueDate,
    this.issuedTo,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (issueDate != null) 'issueDate': issueDate!.toIso8601String().split('T')[0],
      if (issuedTo != null) 'issuedTo': issuedTo,
      if (notes != null) 'notes': notes,
    };
  }

  factory IssueRequestDto.fromJson(Map<String, dynamic> json) {
    return IssueRequestDto(
      issueDate: json['issueDate'] != null 
          ? DateTime.parse(json['issueDate']) 
          : null,
      issuedTo: json['issuedTo'],
      notes: json['notes'],
    );
  }
}
