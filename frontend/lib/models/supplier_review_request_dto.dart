class SupplierReviewRequestDto {
  final int rating;
  final String comment;

  SupplierReviewRequestDto({required this.rating, required this.comment});

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
      };
}
