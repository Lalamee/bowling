import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoritePart {
  final String key;
  final String name;
  final String? catalogNumber;

  const FavoritePart({
    required this.key,
    required this.name,
    this.catalogNumber,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'catalogNumber': catalogNumber,
      };

  factory FavoritePart.fromJson(Map<String, dynamic> json) {
    return FavoritePart(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      catalogNumber: json['catalogNumber']?.toString(),
    );
  }
}

class FavoritesStorage {
  static const String _ordersKey = 'favorite_orders';
  static const String _partsKey = 'favorite_parts';

  static String partKey({int? partId, String? catalogNumber}) {
    final catalog = catalogNumber?.trim();
    if (catalog != null && catalog.isNotEmpty) {
      return 'CAT:$catalog';
    }
    return 'ID:${partId ?? 0}';
  }

  Future<Set<int>> loadFavoriteOrders() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_ordersKey) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> saveFavoriteOrders(Set<int> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_ordersKey, ids.map((id) => id.toString()).toList());
  }

  Future<void> toggleFavoriteOrder(int orderId) async {
    final ids = await loadFavoriteOrders();
    if (ids.contains(orderId)) {
      ids.remove(orderId);
    } else {
      ids.add(orderId);
    }
    await saveFavoriteOrders(ids);
  }

  Future<List<FavoritePart>> loadFavoriteParts() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_partsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => FavoritePart.fromJson(Map<String, dynamic>.from(e)))
        .where((part) => part.key.isNotEmpty && part.name.isNotEmpty)
        .toList();
  }

  Future<void> saveFavoriteParts(List<FavoritePart> parts) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(parts.map((part) => part.toJson()).toList());
    await sp.setString(_partsKey, raw);
  }

  Future<void> toggleFavoritePart(FavoritePart part) async {
    final parts = await loadFavoriteParts();
    final existingIndex = parts.indexWhere((item) => item.key == part.key);
    if (existingIndex >= 0) {
      parts.removeAt(existingIndex);
    } else {
      parts.add(part);
    }
    await saveFavoriteParts(parts);
  }

  Future<void> removeFavoritePart(String key) async {
    final parts = await loadFavoriteParts();
    parts.removeWhere((part) => part.key == key);
    await saveFavoriteParts(parts);
  }
}
