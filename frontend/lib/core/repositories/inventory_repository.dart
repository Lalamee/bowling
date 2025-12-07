import 'package:dio/dio.dart';

import '../../api/api_core.dart';
import '../../models/part_dto.dart';
import '../../models/warehouse_summary_dto.dart';

class InventoryRepository {
  final Dio _dio = ApiCore().dio;

  Future<List<WarehouseSummaryDto>> getWarehouses() async {
    final res = await _dio.get('/api/inventory/warehouses');
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .whereType<Map>()
          .map((e) => WarehouseSummaryDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  Future<List<PartDto>> search({
    String query = '',
    int? warehouseId,
    int? clubId,
    String? availability,
    String? category,
    int? componentId,
  }) async {
    final params = <String, dynamic>{'query': query};
    if (warehouseId != null) {
      params['warehouseId'] = warehouseId;
    }
    if (clubId != null) {
      params['clubId'] = clubId;
    }
    if (availability != null) {
      params['availability'] = availability;
    }
    if (category != null) {
      params['category'] = category;
    }
    if (componentId != null) {
      params['componentId'] = componentId;
    }
    final res = await _dio.get('/api/inventory/search', queryParameters: params);
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .whereType<Map>()
          .map((e) => PartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  Future<List<PartDto>> getWarehouseInventory({
    required int warehouseId,
    String query = '',
    String? category,
    int? componentId,
  }) async {
    final params = <String, dynamic>{'query': query};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (componentId != null) {
      params['componentId'] = componentId;
    }
    final res = await _dio.get('/api/inventory/warehouses/$warehouseId/items', queryParameters: params);
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .whereType<Map>()
          .map((e) => PartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const [];
  }

  Future<PartDto?> getById(String id) async {
    final res = await _dio.get('/api/inventory/$id');
    if (res.statusCode == 200 && res.data is Map) {
      return PartDto.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }
}
