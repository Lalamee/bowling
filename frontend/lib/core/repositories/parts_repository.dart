
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

  Future<PartsCatalogResponseDto?> createOrFindCatalog({
    required String catalogNumber,
    String? name,
    String? description,
    String? categoryCode,
    bool? isUnique,
  }) async {
    final payload = {
      'catalogNumber': catalogNumber,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (categoryCode != null && categoryCode.trim().isNotEmpty) 'categoryCode': categoryCode.trim(),
      if (isUnique != null) 'isUnique': isUnique,
    };
    final res = await _dio.post('/api/parts/catalog', data: payload);
    if (res.statusCode == 200 && res.data is Map) {
      return PartsCatalogResponseDto.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }
}
