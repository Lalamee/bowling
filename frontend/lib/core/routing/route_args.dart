class PdfReaderArgs {
  final String assetPath;
  final String title;
  const PdfReaderArgs({required this.assetPath, required this.title});
}

class OrderSummaryArgs {
  final String orderId;
  const OrderSummaryArgs(this.orderId);
}

class EditMechanicProfileArgs {
  final String? mechanicId;
  const EditMechanicProfileArgs({this.mechanicId});
}
