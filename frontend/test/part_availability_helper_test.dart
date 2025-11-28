import 'package:bowling_market/core/utils/part_availability_helper.dart';
import 'package:bowling_market/models/part_dto.dart';
import 'package:bowling_market/models/part_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marks available when free quantity is enough', () {
    final request = RequestedPartDto(
      catalogNumber: 'ABC-1',
      partName: 'Sensor',
      quantity: 2,
    );
    final inventory = [
      PartDto(inventoryId: 1, catalogId: 10, catalogNumber: 'ABC-1', quantity: 5, reservedQuantity: 1, location: 'A1')
    ];

    final result = PartAvailabilityHelper.resolve(request, inventory);

    expect(result.available, isTrue);
    expect(result.location, 'A1');
  });

  test('marks shortage when free quantity is missing', () {
    final request = RequestedPartDto(
      catalogNumber: 'XYZ',
      partName: 'Motor',
      quantity: 5,
    );
    final inventory = [PartDto(inventoryId: 2, catalogId: 11, catalogNumber: 'XYZ', quantity: 3, reservedQuantity: 0)];

    final result = PartAvailabilityHelper.resolve(request, inventory);

    expect(result.available, isFalse);
  });
}
