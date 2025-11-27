import '../../api/api_service.dart';
import '../../models/equipment_component_dto.dart';

class EquipmentComponentRepository {
  final ApiService _api = ApiService();

  Future<List<EquipmentComponentDto>> fetchRoots() {
    return _api.getEquipmentComponents();
  }

  Future<List<EquipmentComponentDto>> fetchChildren(int parentId) {
    return _api.getEquipmentComponents(parentId: parentId);
  }
}
