import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/purchase_order_detail_dto.dart';
import 'package:bowling_market/models/supplier_complaint_status_update_dto.dart';

void main() {
  test('PurchaseOrderPartDto parses warehouse placement fields', () {
    final dto = PurchaseOrderPartDto.fromJson({
      'partId': 10,
      'partName': 'Подшипник',
      'catalogNumber': 'ABC-1',
      'orderedQuantity': 4,
      'acceptedQuantity': 2,
      'status': 'PARTIALLY_ACCEPTED',
      'warehouseId': 3,
      'inventoryId': 55,
      'inventoryLocation': 'Секция A / Полка 2',
    });

    expect(dto.partId, 10);
    expect(dto.inventoryId, 55);
    expect(dto.warehouseId, 3);
    expect(dto.inventoryLocation, contains('Секция'));
  });

  test('SupplierComplaintStatusUpdateDto serializes optional fields', () {
    final dto = SupplierComplaintStatusUpdateDto(
      status: 'RESOLVED',
      resolved: true,
      resolutionNotes: 'Подтверждена недопоставка, согласован возврат.',
    );

    final json = dto.toJson();
    expect(json['status'], 'RESOLVED');
    expect(json['resolved'], isTrue);
    expect(json['resolutionNotes'], contains('недопоставка'));
  });
}
