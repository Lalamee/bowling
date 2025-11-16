import '../../models/maintenance_request_response_dto.dart';
import '../../features/knowledge_base/domain/kb_pdf.dart';
import '../../models/purchase_order_summary_dto.dart';

class PdfReaderArgs {
  final KbPdf document;
  const PdfReaderArgs({required this.document});
}

class OrderSummaryArgs {
  final MaintenanceRequestResponseDto? order;
  final String? orderNumber;
  const OrderSummaryArgs({this.order, this.orderNumber});
}

class EditMechanicProfileArgs {
  final String? mechanicId;
  const EditMechanicProfileArgs({this.mechanicId});
}

class ClubWarehouseArgs {
  final int? warehouseId;
  final int? clubId;
  final String? clubName;
  final String? warehouseType;
  final int? inventoryId;
  final String? searchQuery;

  const ClubWarehouseArgs({
    this.warehouseId,
    this.clubId,
    this.clubName,
    this.warehouseType,
    this.inventoryId,
    this.searchQuery,
  });
}

class ClubLanesArgs {
  final int clubId;
  final String? clubName;
  final int? lanesCount;

  const ClubLanesArgs({required this.clubId, this.clubName, this.lanesCount});
}

class SupplyOrderDetailsArgs {
  final int orderId;
  final PurchaseOrderSummaryDto? summary;

  const SupplyOrderDetailsArgs({required this.orderId, this.summary});
}

class WarehouseSelectorArgs {
  final int? preferredClubId;

  const WarehouseSelectorArgs({this.preferredClubId});
}
