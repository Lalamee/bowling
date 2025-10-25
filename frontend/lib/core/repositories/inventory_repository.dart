
import 'package:dio/dio.dart';

import '../../api/api_core.dart';
import '../../models/part_dto.dart';

class InventoryRepository {
  final _dio = ApiCore().dio;

  Future<List<PartDto>> search(String query, {int? clubId}) async {
    final params = <String, dynamic>{'query': query};
    if (clubId != null) {
      params['clubId'] = clubId;
    }
    final res = await _dio.get('/inventory/search', queryParameters: params);
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .whereType<Map>()
          .map((e) => PartDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<PartDto?> getById(String id) async {
    final res = await _dio.get('/inventory/$id');
    if (res.statusCode == 200 && res.data is Map) {
      return PartDto.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }
}
