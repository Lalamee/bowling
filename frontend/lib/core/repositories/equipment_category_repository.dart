import '../../api/api_service.dart';
import '../../models/equipment_category_dto.dart';

class EquipmentCategoryRepository {
  final ApiService _api = ApiService();

  Future<List<EquipmentCategoryDto>> fetchRoots({String? brand}) {
    return _api.getEquipmentCategories(brand: brand, level: 1);
  }

  Future<List<EquipmentCategoryDto>> fetchChildren({
    required int parentId,
    String? brand,
  }) {
    return _api.getEquipmentCategories(parentId: parentId, brand: brand);
  }
}
