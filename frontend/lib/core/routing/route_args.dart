import '../../models/maintenance_request_response_dto.dart';
import '../../features/knowledge_base/domain/kb_pdf.dart';

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
  final int clubId;
  final String? clubName;
  final int? inventoryId;
  final String? searchQuery;

  const ClubWarehouseArgs({required this.clubId, this.clubName, this.inventoryId, this.searchQuery});
}
