class SupplierComplaintStatusUpdateDto {
  final String status;
  final bool? resolved;
  final String? resolutionNotes;

  SupplierComplaintStatusUpdateDto({
    required this.status,
    this.resolved,
    this.resolutionNotes,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        if (resolved != null) 'resolved': resolved,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      };
}
