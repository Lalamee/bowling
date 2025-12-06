import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/core/utils/personal_inventory_filter.dart';
import 'package:bowling_market/models/part_dto.dart';

void main() {
  PartDto buildPart({
    required String number,
    String? name,
    int? qty,
    int? reserved,
    bool? unique,
    DateTime? lastChecked,
    String? description,
    List<int> nodePath = const [],
    String? location,
    String? notes,
  }) {
    return PartDto(
      inventoryId: number.hashCode,
      catalogId: number.hashCode + 1,
      catalogNumber: number,
      officialNameRu: name,
      quantity: qty,
      reservedQuantity: reserved,
      isUnique: unique,
      lastChecked: lastChecked,
      description: description,
      equipmentNodePath: nodePath,
      location: location,
      notes: notes,
    );
  }

  test('filters by query and uniqueness/shortage flags', () {
    final parts = [
      buildPart(number: 'ZIP-001', name: 'Подшипник', qty: 5, reserved: 1, unique: false),
      buildPart(number: 'ZIP-002', name: 'Мотор', qty: 0, reserved: 1, unique: true),
      buildPart(number: 'ZIP-003', name: 'Лента', qty: 2, reserved: 2, unique: false),
    ];

    final onlyUnique = PersonalInventoryFilter.apply(parts, onlyUnique: true);
    expect(onlyUnique.map((e) => e.catalogNumber), ['ZIP-002']);

    final shortage = PersonalInventoryFilter.apply(parts, onlyShortage: true);
    expect(shortage.map((e) => e.catalogNumber), ['ZIP-002', 'ZIP-003']);

    final queryFiltered = PersonalInventoryFilter.apply(parts, query: 'мотор');
    expect(queryFiltered.single.catalogNumber, 'ZIP-002');
  });

  test('category and last checked filters reduce results', () {
    final now = DateTime.now();
    final parts = [
      buildPart(number: 'A1', description: 'узел подачи', nodePath: [10, 11], lastChecked: now.subtract(const Duration(days: 30))),
      buildPart(number: 'A2', description: 'узел возврата', nodePath: [12], lastChecked: now.subtract(const Duration(days: 190))),
      buildPart(number: 'A3', description: 'узел возврата', nodePath: [12], lastChecked: null),
    ];

    final categoryFiltered = PersonalInventoryFilter.apply(parts, categoryFragment: 'возврата');
    expect(categoryFiltered.length, 2);

    final expired = PersonalInventoryFilter.apply(parts, onlyExpiredCheck: true);
    expect(expired.map((e) => e.catalogNumber), ['A2', 'A3']);
  });

  test('matches notes and location in search', () {
    final parts = [
      buildPart(number: 'B1', name: 'Кабель', qty: 2, reserved: 0, location: 'Стеллаж 1', notes: 'для турнира'),
      buildPart(number: 'B2', name: 'Датчик', qty: 1, reserved: 1),
    ];

    final noteHit = PersonalInventoryFilter.apply(parts, query: 'турнира');
    expect(noteHit.single.catalogNumber, 'B1');

    final locationHit = PersonalInventoryFilter.apply(parts, query: 'стеллаж');
    expect(locationHit.single.catalogNumber, 'B1');
  });
}
