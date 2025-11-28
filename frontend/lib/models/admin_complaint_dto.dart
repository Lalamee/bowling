class AdminComplaintDto {
  final int? reviewId;
  final int? supplierId;
  final int? clubId;
  final int? userId;
  final String? complaintStatus;
  final bool? complaintResolved;
  final int? rating;
  final String? comment;
  final String? complaintTitle;
  final String? resolutionNotes;

  const AdminComplaintDto({
    this.reviewId,
    this.supplierId,
    this.clubId,
    this.userId,
    this.complaintStatus,
    this.complaintResolved,
    this.rating,
    this.comment,
    this.complaintTitle,
    this.resolutionNotes,
  });

  factory AdminComplaintDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool? asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
      return null;
    }

    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    return AdminComplaintDto(
      reviewId: asInt(json['reviewId']),
      supplierId: asInt(json['supplierId']),
      clubId: asInt(json['clubId']),
      userId: asInt(json['userId']),
      complaintStatus: asString(json['complaintStatus']),
      complaintResolved: asBool(json['complaintResolved']),
      rating: asInt(json['rating']),
      comment: asString(json['comment']),
      complaintTitle: asString(json['complaintTitle']),
      resolutionNotes: asString(json['resolutionNotes']),
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'supplierId': supplierId,
        'clubId': clubId,
        'userId': userId,
        'complaintStatus': complaintStatus,
        'complaintResolved': complaintResolved,
        'rating': rating,
        'comment': comment,
        'complaintTitle': complaintTitle,
        'resolutionNotes': resolutionNotes,
      };
}
