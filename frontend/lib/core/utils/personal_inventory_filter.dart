import '../../models/part_dto.dart';

/// Helper to filter personal warehouse items by query and flags without relying
/// on widget state, so it can be unit-tested in isolation.
class PersonalInventoryFilter {
  static List<PartDto> apply(
    List<PartDto> source, {
    String query = '',
    bool onlyUnique = false,
    bool onlyShortage = false,
    bool onlyExpiredCheck = false,
    String? categoryFragment,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = categoryFragment?.trim().toLowerCase();
    final now = DateTime.now();

    return source.where((part) {
      if (onlyUnique && part.isUnique != true) {
        return false;
      }

      final shortage = _isShortage(part);
      if (onlyShortage && !shortage) {
        return false;
      }

      if (onlyExpiredCheck && !_isExpiredCheck(part, now)) {
        return false;
      }

      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        final categorySource = _categoryText(part);
        if (!categorySource.contains(normalizedCategory)) {
          return false;
        }
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return _matchesQuery(part, normalizedQuery);
    }).toList();
  }

  static bool _matchesQuery(PartDto part, String normalizedQuery) {
    final fields = <String?>[
      part.catalogNumber,
      part.officialNameRu,
      part.officialNameEn,
      part.commonName,
      part.description,
      part.location,
      part.notes,
    ];
    for (final field in fields) {
      if (field != null && field.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
    }
    return false;
  }

  static String _categoryText(PartDto part) {
    final buffer = StringBuffer();
    if (part.description != null && part.description!.isNotEmpty) {
      buffer.write(part.description!.toLowerCase());
    }
    if (part.equipmentNodePath.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('|');
      buffer.write(part.equipmentNodePath.join('>'));
    }
    if (part.equipmentNodeId != null) {
      if (buffer.isNotEmpty) buffer.write('|');
      buffer.write(part.equipmentNodeId.toString());
    }
    return buffer.toString();
  }

  static bool _isShortage(PartDto part) {
    final quantity = part.quantity;
    final reserved = part.reservedQuantity ?? 0;
    if (quantity == null) return false;
    return quantity <= reserved || quantity == 0;
  }

  static bool _isExpiredCheck(PartDto part, DateTime now) {
    final lastChecked = part.lastChecked;
    if (lastChecked == null) {
      return true;
    }
    return now.difference(lastChecked).inDays >= 180;
  }
}
