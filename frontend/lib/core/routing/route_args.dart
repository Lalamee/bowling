import '../../models/maintenance_request_response_dto.dart';

class PdfReaderArgs {
  final String assetPath;
  final String title;
  const PdfReaderArgs({required this.assetPath, required this.title});
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
