
import 'package:dio/dio.dart';

import '../../api/api_core.dart';

class UserRepository {
  final _dio = ApiCore().dio;

  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: Options(
          responseType: ResponseType.json,
          headers: const {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      throw ApiException('Не удалось загрузить профиль пользователя', statusCode: response.statusCode);
    } on DioException catch (error) {
      final root = error.error;
      if (root is ApiException) {
        throw root;
      }
      throw ApiException(
        'Не удалось загрузить профиль пользователя',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
