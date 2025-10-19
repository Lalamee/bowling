
import '../../api/api_core.dart';

class UserRepository {
  final _dio = ApiCore().dio;

  Future<Map<String, dynamic>?> me() async {
    final r = await _dio.get('/api/auth/me');
    if (r.statusCode == 200 && r.data is Map) return Map<String, dynamic>.from(r.data as Map);
    return null;
  }
}
