class SupplierComplaintRequestDto {
  final String title;
  final String description;
  final String status;

  SupplierComplaintRequestDto({
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status,
      };
}
