
import '../../api/api_core.dart';
import '../../models/parts_catalog_response_dto.dart';
import '../../models/parts_search_dto.dart';

class PartsRepository {
  final _dio = ApiCore().dio;

  Future<List<PartsCatalogResponseDto>> all() async {
    final res = await _dio.get('/api/parts/all');
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .map((e) => PartsCatalogResponseDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<List<PartsCatalogResponseDto>> search(String query) async {
    final dto = PartsSearchDto(searchQuery: query);
    final res = await _dio.post('/api/parts/search', data: dto.toJson());
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .map((e) => PartsCatalogResponseDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }
}
