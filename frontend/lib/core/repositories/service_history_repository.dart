
import '../../api/api_core.dart';
import '../../api/api_service.dart';
import '../../models/service_history_dto.dart';

class ServiceHistoryRepository {
  final _dio = ApiCore().dio;
  final _api = ApiService();

  /// Получить историю обслуживания клуба
  Future<List<ServiceHistoryDto>> getByClub(int clubId) async {
    return await _api.getServiceHistoryByClub(clubId);
  }

  /// Получить запись по ID
  Future<ServiceHistoryDto?> getById(int id) async {
    try {
      return await _api.getServiceHistory(id);
    } catch (e) {
      return null;
    }
  }

  /// Создать новую запись истории обслуживания
  Future<ServiceHistoryDto?> create(ServiceHistoryDto serviceHistory) async {
    try {
      return await _api.createServiceHistory(serviceHistory);
    } catch (e) {
      rethrow;
    }
  }
}
