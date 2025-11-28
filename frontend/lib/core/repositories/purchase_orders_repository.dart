import '../../api/api_service.dart';
import '../../models/purchase_order_acceptance_request_dto.dart';
import '../../models/purchase_order_detail_dto.dart';
import '../../models/purchase_order_summary_dto.dart';
import '../../models/supplier_complaint_request_dto.dart';
import '../../models/supplier_complaint_status_update_dto.dart';
import '../../models/supplier_review_request_dto.dart';

class PurchaseOrdersRepository {
  final ApiService _api = ApiService();

  Future<List<PurchaseOrderSummaryDto>> list({
    int? clubId,
    bool archived = false,
    String? status,
    bool? hasComplaint,
    bool? hasReview,
    String? supplier,
    DateTime? from,
    DateTime? to,
  }) async {
    return _api.getPurchaseOrders(
      clubId: clubId,
      archived: archived,
      status: status,
      hasComplaint: hasComplaint,
      hasReview: hasReview,
      supplier: supplier,
      from: from,
      to: to,
    );
  }

  Future<PurchaseOrderDetailDto> get(int orderId) async {
    return _api.getPurchaseOrder(orderId);
  }

  Future<PurchaseOrderDetailDto> accept(int orderId, PurchaseOrderAcceptanceRequestDto request) async {
    return _api.acceptPurchaseOrder(orderId, request);
  }

  Future<PurchaseOrderDetailDto> review(int orderId, SupplierReviewRequestDto request) async {
    return _api.reviewPurchaseOrder(orderId, request);
  }

  Future<PurchaseOrderDetailDto> complaint(int orderId, SupplierComplaintRequestDto request) async {
    return _api.complainPurchaseOrder(orderId, request);
  }

  Future<PurchaseOrderDetailDto> updateComplaintStatus(
      int orderId, int reviewId, SupplierComplaintStatusUpdateDto request) async {
    return _api.updateComplaintStatus(orderId, reviewId, request);
  }
}
