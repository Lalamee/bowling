
import '../../api/api_core.dart';

class AdminUsersRepository {
  final _dio = ApiCore().dio;

  Future<bool> verify(String userId) async {
    final res = await _dio.put('/api/admin/users/$userId/verify');
    return res.statusCode == 200;
  }

  Future<bool> activate(String userId) async {
    final res = await _dio.put('/api/admin/users/$userId/activate');
    return res.statusCode == 200;
  }

  Future<bool> deactivate(String userId) async {
    final res = await _dio.put('/api/admin/users/$userId/deactivate');
    return res.statusCode == 200;
  }

  Future<bool> reject(String userId) async {
    final res = await _dio.delete('/api/admin/users/$userId/reject');
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
