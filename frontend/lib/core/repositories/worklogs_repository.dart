
import '../../api/api_core.dart';
import '../../models/page_response.dart';
import '../../models/work_log_dto.dart';
import '../../models/work_log_search_dto.dart';

class WorklogsRepository {
  final _dio = ApiCore().dio;

  Future<PageResponse<WorkLogDto>> search(WorkLogSearchDto filter) async {
    final res = await _dio.post('/api/worklogs/search', data: filter.toJson());
    if (res.statusCode == 200 && res.data is Map) {
      return PageResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        (item) => WorkLogDto.fromJson(item),
      );
    }

    return PageResponse<WorkLogDto>(
      content: const [],
      totalElements: 0,
      totalPages: 0,
      size: 0,
      number: filter.page,
    );
  }

  Future<bool> create(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/worklogs', data: body);
    return res.statusCode == 201 || res.statusCode == 200;
  }
}
