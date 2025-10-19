
import '../../api/api_core.dart';

class WorklogsRepository {
  final _dio = ApiCore().dio;

  Future<List<dynamic>> search(Map<String, dynamic> filter) async {
    final res = await _dio.post('/api/worklogs/search', data: filter);
    if (res.statusCode == 200 && res.data is List) return List.from(res.data as List);
    return [];
  }

  Future<bool> create(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/worklogs', data: body);
    return res.statusCode == 201 || res.statusCode == 200;
  }
}
