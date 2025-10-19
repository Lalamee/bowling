
import '../../api/api_core.dart';

class PartsRepository {
  final _dio = ApiCore().dio;

  Future<List<dynamic>> all() async {
    final res = await _dio.get('/api/parts/all');
    if (res.statusCode == 200 && res.data is List) return List.from(res.data as List);
    return [];
  }

  Future<List<dynamic>> search(String query) async {
    final res = await _dio.post('/api/parts/search', data: {'q': query});
    if (res.statusCode == 200 && res.data is List) return List.from(res.data as List);
    return [];
  }
}
