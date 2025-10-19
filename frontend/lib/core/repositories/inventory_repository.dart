
import '../../api/api_core.dart';
import 'package:dio/dio.dart';

class InventoryRepository {
  final _dio = ApiCore().dio;

  Future<List<dynamic>> search(String q) async {
    final res = await _dio.get('/inventory/search', queryParameters: {'q': q});
    if (res.statusCode == 200 && res.data is List) return List.from(res.data as List);
    return [];
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final res = await _dio.get('/inventory/$id');
    if (res.statusCode == 200 && res.data is Map) return Map<String, dynamic>.from(res.data as Map);
    return null;
  }
}
