
import '../../api/api_core.dart';
import '../../api/api_service.dart';
import '../../models/maintenance_request_response_dto.dart';
import '../../models/part_request_dto.dart';
import '../../models/stock_issue_decision_dto.dart';

class MaintenanceRepository {
  final _dio = ApiCore().dio;
  final _api = ApiService();

  /// Получить все заявки
  Future<List<MaintenanceRequestResponseDto>> getAllRequests() async {
    return await _api.getAllMaintenanceRequests();
  }

  Future<List<MaintenanceRequestResponseDto>> getRequestsByClub(int clubId) async {
    return await _api.getMaintenanceRequestsByClub(clubId);
  }

  /// Получить заявки по статусу
  Future<List<MaintenanceRequestResponseDto>> getRequestsByStatus(String status) async {
    return await _api.getMaintenanceRequestsByStatus(status);
  }

  /// Получить заявки механика
  Future<List<MaintenanceRequestResponseDto>> requestsForMechanic(int mechanicId) async {
    return await _api.getMaintenanceRequestsByMechanic(mechanicId);
  }

  /// Получить заявку по ID
  Future<MaintenanceRequestResponseDto?> getById(int id) async {
    try {
      final res = await _dio.get('/api/maintenance/requests/$id');
      if (res.statusCode == 200 && res.data is Map) {
        return MaintenanceRequestResponseDto.fromJson(res.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Создать новую заявку
  Future<MaintenanceRequestResponseDto?> create(PartRequestDto request) async {
    try {
      return await _api.createMaintenanceRequest(request);
    } catch (e) {
      rethrow;
    }
  }

  Future<MaintenanceRequestResponseDto> addPartsToRequest(
    int requestId,
    List<RequestedPartDto> parts,
  ) async {
    try {
      return await _api.addPartsToMaintenanceRequest(requestId, parts);
    } catch (e) {
      rethrow;
    }
  }

  /// Закрыть заявку
  Future<MaintenanceRequestResponseDto?> close(int id, {String? notes}) async {
    try {
      return await _api.closeMaintenanceRequest(id, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Завершить заявку
  Future<MaintenanceRequestResponseDto?> complete(int id) async {
    try {
      return await _api.completeMaintenanceRequest(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Отметить как неремонтопригодное
  Future<MaintenanceRequestResponseDto?> markUnrepairable(int id, String reason) async {
    try {
      final request = {'rejectionReason': reason};
      final res = await _dio.put(
        '/api/maintenance/requests/$id/unrepairable',
        data: request,
      );
      if (res.statusCode == 200 && res.data is Map) {
        return MaintenanceRequestResponseDto.fromJson(res.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Одобрить заявку
  Future<MaintenanceRequestResponseDto?> approve(
    int id,
    Map<int, bool> availability,
    String? notes,
  ) async {
    try {
      final request = {
        'managerNotes': notes ?? '',
        'partsAvailability': availability.entries
            .map((entry) => {
                  'partId': entry.key,
                  'available': entry.value,
                })
            .toList(),
      };
      final res = await _dio.put(
        '/api/maintenance/requests/$id/approve',
        data: request,
      );
      if (res.statusCode == 200 && res.data is Map) {
        return MaintenanceRequestResponseDto.fromJson(res.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Отклонить заявку
  Future<MaintenanceRequestResponseDto?> reject(int id, String reason) async {
    try {
      final request = {'rejectionReason': reason};
      final res = await _dio.put(
        '/api/maintenance/requests/$id/reject',
        data: request,
      );
      if (res.statusCode == 200 && res.data is Map) {
        return MaintenanceRequestResponseDto.fromJson(res.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Частичное согласование/выдача со склада
  Future<MaintenanceRequestResponseDto?> issueFromStock(
    int id,
    StockIssueDecisionDto decision,
  ) async {
    try {
      return await _api.issueFromStock(id, decision);
    } catch (e) {
      rethrow;
    }
  }
}
