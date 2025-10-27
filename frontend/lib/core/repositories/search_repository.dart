import 'package:dio/dio.dart';

import '../../api/api_core.dart';
import '../../models/global_search_response_dto.dart';

class SearchRepository {
  final Dio _dio = ApiCore().dio;

  Future<GlobalSearchResponseDto> searchGlobal(String query, {int limit = 5}) async {
    final params = <String, dynamic>{'limit': limit};
    if (query.trim().isNotEmpty) {
      params['query'] = query.trim();
    }

    final response = await _dio.get('/api/search/global', queryParameters: params);
    if (response.statusCode == 200 && response.data is Map) {
      return GlobalSearchResponseDto.fromJson(Map<String, dynamic>.from(response.data as Map));
    }

    return GlobalSearchResponseDto(parts: const [], maintenanceRequests: const [], workLogs: const [], clubs: const []);
  }
}
