import 'purchase_order_summary_dto.dart';

class PurchaseOrderDetailDto extends PurchaseOrderSummaryDto {
  final String? supplierContact;
  final String? supplierEmail;
  final String? supplierPhone;
  final List<PurchaseOrderPartDto> parts;
  final List<SupplierReviewDto> reviews;
  final List<SupplierReviewDto> complaints;

  PurchaseOrderDetailDto({
    required super.orderId,
    super.requestId,
    super.clubId,
    super.clubName,
    required super.status,
    super.orderDate,
    super.expectedDeliveryDate,
    super.actualDeliveryDate,
    super.supplierName,
    super.supplierInn,
    super.totalPositions,
    super.acceptedPositions,
    required super.hasReview,
    required super.hasComplaint,
    this.supplierContact,
    this.supplierEmail,
    this.supplierPhone,
    required this.parts,
    required this.reviews,
    required this.complaints,
  });

  factory PurchaseOrderDetailDto.fromJson(Map<String, dynamic> json) {
    final summary = PurchaseOrderSummaryDto.fromJson(json);
    return PurchaseOrderDetailDto(
      orderId: summary.orderId,
      requestId: summary.requestId,
      clubId: summary.clubId,
      clubName: summary.clubName,
      status: summary.status,
      orderDate: summary.orderDate,
      expectedDeliveryDate: summary.expectedDeliveryDate,
      actualDeliveryDate: summary.actualDeliveryDate,
      supplierName: summary.supplierName,
      supplierInn: summary.supplierInn,
      totalPositions: summary.totalPositions,
      acceptedPositions: summary.acceptedPositions,
      hasReview: summary.hasReview,
      hasComplaint: summary.hasComplaint,
      supplierContact: json['supplierContact'] as String?,
      supplierEmail: json['supplierEmail'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      parts: (json['parts'] as List<dynamic>? ?? [])
          .map((e) => PurchaseOrderPartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => SupplierReviewDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      complaints: (json['complaints'] as List<dynamic>? ?? [])
          .map((e) => SupplierReviewDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class PurchaseOrderPartDto {
  final int partId;
  final String? partName;
  final String? catalogNumber;
  final int? orderedQuantity;
  final int? acceptedQuantity;
  final String? status;
  final String? rejectionReason;
  final String? acceptanceComment;
  final int? warehouseId;
  final int? inventoryId;
  final String? inventoryLocation;

  PurchaseOrderPartDto({
    required this.partId,
    this.partName,
    this.catalogNumber,
    this.orderedQuantity,
    this.acceptedQuantity,
    this.status,
    this.rejectionReason,
    this.acceptanceComment,
    this.warehouseId,
    this.inventoryId,
    this.inventoryLocation,
  });

  factory PurchaseOrderPartDto.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderPartDto(
      partId: (json['partId'] as num).toInt(),
      partName: json['partName'] as String?,
      catalogNumber: json['catalogNumber'] as String?,
      orderedQuantity: (json['orderedQuantity'] as num?)?.toInt(),
      acceptedQuantity: (json['acceptedQuantity'] as num?)?.toInt(),
      status: json['status']?.toString(),
      rejectionReason: json['rejectionReason'] as String?,
      acceptanceComment: json['acceptanceComment'] as String?,
      warehouseId: (json['warehouseId'] as num?)?.toInt(),
      inventoryId: (json['inventoryId'] as num?)?.toInt(),
      inventoryLocation: json['inventoryLocation'] as String?,
    );
  }
}

class SupplierReviewDto {
  final int reviewId;
  final int? rating;
  final String? comment;
  final bool complaint;
  final String? complaintStatus;
  final bool? complaintResolved;
  final String? complaintTitle;
  final String? resolutionNotes;
  final DateTime? createdAt;

  SupplierReviewDto({
    required this.reviewId,
    this.rating,
    this.comment,
    required this.complaint,
    this.complaintStatus,
    this.complaintResolved,
    this.complaintTitle,
    this.resolutionNotes,
    this.createdAt,
  });

  factory SupplierReviewDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return SupplierReviewDto(
      reviewId: (json['reviewId'] as num).toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      complaint: json['complaint'] == true,
      complaintStatus: json['complaintStatus'] as String?,
      complaintResolved: json['complaintResolved'] as bool?,
      complaintTitle: json['complaintTitle'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: _d(json['createdAt']),
    );
  }
}
