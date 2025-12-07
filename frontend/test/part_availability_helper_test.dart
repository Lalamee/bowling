import 'package:bowling_market/core/utils/part_availability_helper.dart';
import 'package:bowling_market/models/part_dto.dart';
import 'package:bowling_market/models/part_request_dto.dart';
import 'package:bowling_market/models/warehouse_summary_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves availability using backend flags and warehouse metadata', () {
    final req = RequestedPartDto(
      catalogNumber: 'ABC-1',
      partName: 'Кольцо',
      quantity: 1,
    );
    final warehouse = WarehouseSummaryDto(
      warehouseId: 4,
      title: 'Личный zip-склад',
      warehouseType: 'PERSONAL',
      personalAccess: true,
      locationReference: 'Бокс 1',
    );
    final parts = [
      PartDto(
        inventoryId: 10,
        catalogId: 55,
        catalogNumber: 'ABC-1',
        quantity: 1,
        reservedQuantity: 0,
        warehouseId: 4,
        location: 'Полка А',
        isAvailable: true,
      ),
    ];

    final result = PartAvailabilityHelper.resolve(req, parts, warehouses: {4: warehouse});

    expect(result.available, isTrue);
    expect(result.location, 'Полка А');
    expect(result.warehouseHint, contains('Личный'));
    expect(result.warehouseType, 'PERSONAL');
  });

  test('marks part as unavailable when free stock is insufficient', () {
    final req = RequestedPartDto(
      catalogNumber: 'MISS-1',
      partName: 'Деталь',
      quantity: 3,
    );
    final parts = [
      PartDto(
        inventoryId: 2,
        catalogId: 90,
        catalogNumber: 'MISS-1',
        quantity: 2,
        reservedQuantity: 0,
      ),
    ];

    final result = PartAvailabilityHelper.resolve(req, parts);
    expect(result.available, isFalse);
    expect(result.location, isNull);
  });
}
