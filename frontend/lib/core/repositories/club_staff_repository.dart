
import '../../api/api_core.dart';

class ClubStaffRepository {
  final _dio = ApiCore().dio;

  /// Получить список сотрудников клуба
  Future<List<dynamic>> getClubStaff(int clubId) async {
    try {
      final res = await _dio.get('/api/clubs/$clubId/staff');
      if (res.statusCode == 200 && res.data is List) {
        return List.from(res.data as List);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Назначить сотрудника в клуб
  Future<bool> assignStaff(int clubId, int userId, {String? role}) async {
    try {
      final body = role != null ? {'role': role} : {};
      final res = await _dio.post('/api/clubs/$clubId/staff/$userId', data: body);
      return res.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить сотрудника из клуба
  Future<bool> removeStaff(int clubId, int userId) async {
    try {
      final res = await _dio.delete('/api/clubs/$clubId/staff/$userId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить роль сотрудника
  Future<bool> updateStaffRole(int clubId, int userId, String role) async {
    try {
      final res = await _dio.put(
        '/api/clubs/$clubId/staff/$userId/role',
        data: {'role': role},
      );
      return res.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createManager(
    int clubId, {
    required String fullName,
    required String phone,
    String? email,
    String? password,
  }) async {
    try {
      final payload = <String, dynamic>{
        'fullName': fullName,
        'phone': phone,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
      };
      final res = await _dio.post('/api/clubs/$clubId/managers', data: payload);
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
