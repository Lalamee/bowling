import '../../models/part_dto.dart';
import '../../models/part_request_dto.dart';

class PartAvailabilityResult {
  final bool available;
  final String? location;
  final String? warehouseHint;

  const PartAvailabilityResult({
    required this.available,
    this.location,
    this.warehouseHint,
  });
}

class PartAvailabilityHelper {
  static PartAvailabilityResult resolve(RequestedPartDto request, List<PartDto> inventory) {
    final match = inventory.firstWhere(
      (p) => p.catalogNumber.trim() == request.catalogNumber.trim(),
      orElse: () => inventory.isNotEmpty ? inventory.first : PartDto(
        inventoryId: 0,
        catalogId: request.catalogId ?? 0,
        catalogNumber: request.catalogNumber,
      ),
    );
    final qty = match.quantity ?? 0;
    final reserved = match.reservedQuantity ?? 0;
    final freeQty = qty - reserved;
    final available = freeQty >= request.quantity;
    return PartAvailabilityResult(
      available: available,
      location: match.location,
      warehouseHint: match.warehouseId != null ? 'Склад #${match.warehouseId}' : null,
    );
  }
}
