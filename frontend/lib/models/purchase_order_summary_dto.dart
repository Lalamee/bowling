class PurchaseOrderSummaryDto {
  final int orderId;
  final int? requestId;
  final int? clubId;
  final String? clubName;
  final String? supplierName;
  final String? supplierInn;
  final String status;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final int? totalPositions;
  final int? acceptedPositions;
  final bool hasReview;
  final bool hasComplaint;

  PurchaseOrderSummaryDto({
    required this.orderId,
    this.requestId,
    this.clubId,
    this.clubName,
    this.supplierName,
    this.supplierInn,
    required this.status,
    this.orderDate,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.totalPositions,
    this.acceptedPositions,
    required this.hasReview,
    required this.hasComplaint,
  });

  factory PurchaseOrderSummaryDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(dynamic v) => (v is String && v.isNotEmpty) ? DateTime.parse(v) : null;
    return PurchaseOrderSummaryDto(
      orderId: (json['orderId'] as num).toInt(),
      requestId: (json['requestId'] as num?)?.toInt(),
      clubId: (json['clubId'] as num?)?.toInt(),
      clubName: json['clubName'] as String?,
      supplierName: json['supplierName'] as String?,
      supplierInn: json['supplierInn'] as String?,
      status: json['status']?.toString() ?? 'PENDING',
      orderDate: _d(json['orderDate']),
      expectedDeliveryDate: _d(json['expectedDeliveryDate']),
      actualDeliveryDate: _d(json['actualDeliveryDate']),
      totalPositions: (json['totalPositions'] as num?)?.toInt(),
      acceptedPositions: (json['acceptedPositions'] as num?)?.toInt(),
      hasReview: json['hasReview'] == true,
      hasComplaint: json['hasComplaint'] == true,
    );
  }
}
