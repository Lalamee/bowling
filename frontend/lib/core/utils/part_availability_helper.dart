import '../../models/part_dto.dart';
import '../../models/part_request_dto.dart';
import '../../models/warehouse_summary_dto.dart';

class PartAvailabilityResult {
  final bool available;
  final String? location;
  final String? warehouseHint;
  final int? warehouseId;
  final String? warehouseType;

  const PartAvailabilityResult({
    required this.available,
    this.location,
    this.warehouseHint,
    this.warehouseId,
    this.warehouseType,
  });
}

class PartAvailabilityHelper {
  static PartAvailabilityResult resolve(
    RequestedPartDto request,
    List<PartDto> inventory, {
    Map<int, WarehouseSummaryDto>? warehouses,
  }) {
    PartDto? findMatch() {
      final normalizedCatalog = request.catalogNumber.trim().toLowerCase();
      for (final part in inventory) {
        if (part.catalogNumber.trim().toLowerCase() == normalizedCatalog) {
          return part;
        }
        if (request.catalogId != null && part.catalogId == request.catalogId) {
          return part;
        }
      }
      return inventory.isNotEmpty
          ? inventory.first
          : PartDto(
              inventoryId: 0,
              catalogId: request.catalogId ?? 0,
              catalogNumber: request.catalogNumber,
            );
    }

    final match = findMatch();
    final qty = match.quantity ?? 0;
    final reserved = match.reservedQuantity ?? 0;
    final freeQty = qty - reserved;
    final availableFlag = match.isAvailable;
    final available = availableFlag ?? freeQty >= request.quantity;
    final warehouseId = match.warehouseId;
    final warehouse = warehouseId != null ? warehouses?[warehouseId] : null;
    final warehouseHint = warehouse?.title ??
        (warehouse?.warehouseType == 'PERSONAL'
            ? 'Личный склад'
            : (warehouseId != null ? 'Склад #$warehouseId' : null));
    final location = match.location ?? warehouse?.locationReference ?? request.location;
    return PartAvailabilityResult(
      available: available,
      location: location,
      warehouseHint: warehouseHint,
      warehouseId: warehouseId,
      warehouseType: warehouse?.warehouseType,
    );
  }
}
