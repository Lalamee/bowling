class CloseRequestDto {
  final String? completionNotes;
  final DateTime? completionDate;

  CloseRequestDto({
    this.completionNotes,
    this.completionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (completionNotes != null) 'completionNotes': completionNotes,
      if (completionDate != null) 'completionDate': completionDate!.toIso8601String().split('T')[0],
    };
  }

  factory CloseRequestDto.fromJson(Map<String, dynamic> json) {
    return CloseRequestDto(
      completionNotes: json['completionNotes'],
      completionDate: json['completionDate'] != null 
          ? DateTime.parse(json['completionDate']) 
          : null,
    );
  }
}
