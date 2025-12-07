import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/purchase_order_acceptance_request_dto.dart';

void main() {
  test('serializes supplier and placement fields for acceptance', () {
    final request = PurchaseOrderAcceptanceRequestDto(
      supplierInn: '7701234567',
      supplierName: 'ООО «Боулинг-Снаб»',
      supplierContactPerson: 'Иван Иванов',
      supplierPhone: '+79991112233',
      supplierEmail: 'supply@example.com',
      supplierVerified: true,
      parts: [
        PartAcceptanceDto(
          partId: 10,
          status: 'ACCEPTED',
          acceptedQuantity: 2,
          comment: 'Без повреждений',
          storageLocation: 'Зона A',
          shelfCode: 'S-1',
          cellCode: 'C-3',
          placementNotes: 'Проверено при приемке',
        ),
      ],
    );

    final json = request.toJson();
    expect(json['supplierInn'], '7701234567');
    expect(json['supplierName'], 'ООО «Боулинг-Снаб»');
    expect(json['supplierContactPerson'], 'Иван Иванов');
    expect(json['supplierPhone'], '+79991112233');
    expect(json['supplierEmail'], 'supply@example.com');
    expect(json['supplierVerified'], true);
    final parts = json['parts'] as List<dynamic>;
    expect(parts.length, 1);
    final partJson = parts.first as Map<String, dynamic>;
    expect(partJson['storageLocation'], 'Зона A');
    expect(partJson['shelfCode'], 'S-1');
    expect(partJson['cellCode'], 'C-3');
    expect(partJson['placementNotes'], 'Проверено при приемке');
  });
});
