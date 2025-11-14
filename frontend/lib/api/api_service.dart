import 'package:dio/dio.dart';
import 'api_core.dart';
import '../models/login_response_dto.dart';
import '../models/user_login_dto.dart';
import '../models/user_info_dto.dart';
import '../models/register_request_dto.dart';
import '../models/refresh_token_request_dto.dart';
import '../models/password_change_request_dto.dart';
import '../models/standard_response_dto.dart';
import '../models/maintenance_request_response_dto.dart';
import '../models/part_request_dto.dart';
import '../models/approve_reject_request_dto.dart';
import '../models/parts_catalog_response_dto.dart';
import '../models/parts_search_dto.dart';
import '../models/work_log_dto.dart';
import '../models/work_log_search_dto.dart';
import '../models/page_response.dart';
import '../models/service_history_dto.dart';
import '../models/order_parts_request_dto.dart';
import '../models/delivery_request_dto.dart';
import '../models/issue_request_dto.dart';
import '../models/close_request_dto.dart';
import '../models/club_summary_dto.dart';

/// Типизированный API сервис для взаимодействия с backend
class ApiService {
  final ApiCore _core = ApiCore();
  Dio get _dio => _core.dio;

  // ============================================
  // AUTH ENDPOINTS
  // ============================================

  /// POST /api/auth/login - Авторизация пользователя
  Future<LoginResponseDto> login(UserLoginDto credentials) async {
    final response = await _dio.post('/api/auth/login', data: credentials.toJson());
    return LoginResponseDto.fromJson(response.data);
  }

  /// POST /api/auth/register - Регистрация нового пользователя
  Future<StandardResponseDto> register(RegisterRequestDto request) async {
    final response = await _dio.post('/api/auth/register', data: request.toJson());
    return StandardResponseDto.fromJson(response.data);
  }

  /// GET /api/public/clubs - Получение списка клубов
  Future<List<ClubSummaryDto>> getPublicClubs() async {
    final response = await _dio.get('/api/public/clubs');
    return (response.data as List)
        .map((e) => ClubSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/auth/refresh - Обновление токена
  Future<LoginResponseDto> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/api/auth/refresh',
      data: RefreshTokenRequestDto(refreshToken: refreshToken).toJson(),
    );
    return LoginResponseDto.fromJson(response.data);
  }

  /// GET /api/auth/me - Получение информации о текущем пользователе
  Future<UserInfoDto> getCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    return UserInfoDto.fromJson(response.data);
  }

  /// POST /api/auth/logout - Выход из системы
  Future<StandardResponseDto> logout() async {
    final response = await _dio.post('/api/auth/logout', data: {});
    return StandardResponseDto.fromJson(response.data);
  }

  /// POST /api/auth/change-password - Смена пароля
  Future<StandardResponseDto> changePassword(PasswordChangeRequestDto request) async {
    final response = await _dio.post('/api/auth/change-password', data: request.toJson());
    return StandardResponseDto.fromJson(response.data);
  }

  // ============================================
  // MAINTENANCE REQUEST ENDPOINTS
  // ============================================

  /// POST /api/maintenance/requests - Создание заявки на обслуживание
  Future<MaintenanceRequestResponseDto> createMaintenanceRequest(PartRequestDto request) async {
    final response = await _dio.post('/api/maintenance/requests', data: request.toJson());
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// GET /api/maintenance/requests - Получение всех заявок
  Future<List<MaintenanceRequestResponseDto>> getAllMaintenanceRequests() async {
    final response = await _dio.get('/api/maintenance/requests');
    return (response.data as List)
        .map((e) => MaintenanceRequestResponseDto.fromJson(e))
        .toList();
  }

  /// GET /api/maintenance/requests/club/{clubId} - Получение заявок по клубу
  Future<List<MaintenanceRequestResponseDto>> getMaintenanceRequestsByClub(int clubId) async {
    final response = await _dio.get('/api/maintenance/requests/club/$clubId');
    return (response.data as List)
        .map((e) => MaintenanceRequestResponseDto.fromJson(e))
        .toList();
  }

  /// GET /api/maintenance/requests/status/{status} - Получение заявок по статусу
  Future<List<MaintenanceRequestResponseDto>> getMaintenanceRequestsByStatus(String status) async {
    final response = await _dio.get('/api/maintenance/requests/status/$status');
    return (response.data as List)
        .map((e) => MaintenanceRequestResponseDto.fromJson(e))
        .toList();
  }

  /// GET /api/maintenance/requests/mechanic/{mechanicId} - Получение заявок механика
  Future<List<MaintenanceRequestResponseDto>> getMaintenanceRequestsByMechanic(int mechanicId) async {
    final response = await _dio.get('/api/maintenance/requests/mechanic/$mechanicId');
    return (response.data as List)
        .map((e) => MaintenanceRequestResponseDto.fromJson(e))
        .toList();
  }

  /// PUT /api/maintenance/requests/{requestId}/approve - Одобрение заявки
  Future<MaintenanceRequestResponseDto> approveMaintenanceRequest(
    int requestId,
    ApproveRejectRequestDto request,
  ) async {
    final response = await _dio.put(
      '/api/maintenance/requests/$requestId/approve',
      data: request.toJson(),
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{requestId}/reject - Отклонение заявки
  Future<MaintenanceRequestResponseDto> rejectMaintenanceRequest(
    int requestId,
    ApproveRejectRequestDto request,
  ) async {
    final response = await _dio.put(
      '/api/maintenance/requests/$requestId/reject',
      data: request.toJson(),
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/publish - Публикация заявки
  Future<MaintenanceRequestResponseDto> publishMaintenanceRequest(int id) async {
    final response = await _dio.put('/api/maintenance/requests/$id/publish', data: {});
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/assign/{agentId} - Назначение агента
  Future<MaintenanceRequestResponseDto> assignAgent(int id, int agentId) async {
    final response = await _dio.put('/api/maintenance/requests/$id/assign/$agentId', data: {});
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// POST /api/maintenance/requests/{id}/order - Заказ запчастей
  Future<MaintenanceRequestResponseDto> orderParts(int id, OrderPartsRequestDto request) async {
    final response = await _dio.post('/api/maintenance/requests/$id/order', data: request.toJson());
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/deliver - Отметка о доставке
  Future<MaintenanceRequestResponseDto> markDelivered(int id, DeliveryRequestDto request) async {
    final response = await _dio.put('/api/maintenance/requests/$id/deliver', data: request.toJson());
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/issue - Выдача запчастей
  Future<MaintenanceRequestResponseDto> markIssued(int id, IssueRequestDto request) async {
    final response = await _dio.put('/api/maintenance/requests/$id/issue', data: request.toJson());
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/close - Закрытие заявки
  Future<MaintenanceRequestResponseDto> closeMaintenanceRequest(
    int id, [
    CloseRequestDto? request,
  ]) async {
    final response = await _dio.put(
      '/api/maintenance/requests/$id/close',
      data: request?.toJson() ?? {},
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/complete - Завершение заявки механиком
  Future<MaintenanceRequestResponseDto> completeMaintenanceRequest(int id) async {
    final response = await _dio.put('/api/maintenance/requests/$id/complete', data: {});
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// PUT /api/maintenance/requests/{id}/unrepairable - Отметка как неремонтопригодное
  Future<MaintenanceRequestResponseDto> markAsUnrepairable(
    int id,
    ApproveRejectRequestDto request,
  ) async {
    final response = await _dio.put(
      '/api/maintenance/requests/$id/unrepairable',
      data: request.toJson(),
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// POST /api/maintenance/requests/{id}/parts - Добавление деталей в существующую заявку
  Future<MaintenanceRequestResponseDto> addPartsToMaintenanceRequest(
    int id,
    List<RequestedPartDto> parts,
  ) async {
    final response = await _dio.post(
      '/api/maintenance/requests/$id/parts',
      data: {
        'requestedParts': parts.map((e) => e.toJson()).toList(),
      },
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  // ============================================
  // PARTS CATALOG ENDPOINTS
  // ============================================

  /// POST /api/parts/search - Поиск запчастей
  Future<List<PartsCatalogResponseDto>> searchParts(PartsSearchDto searchDto) async {
    final response = await _dio.post('/api/parts/search', data: searchDto.toJson());
    return (response.data as List)
        .map((e) => PartsCatalogResponseDto.fromJson(e))
        .toList();
  }

  /// GET /api/parts/catalog/{catalogNumber} - Получение запчасти по каталожному номеру
  Future<PartsCatalogResponseDto?> getPartByCatalogNumber(String catalogNumber) async {
    try {
      final response = await _dio.get('/api/parts/catalog/$catalogNumber');
      return PartsCatalogResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /api/parts/unique - Получение уникальных запчастей
  Future<List<PartsCatalogResponseDto>> getUniqueParts() async {
    final response = await _dio.get('/api/parts/unique');
    return (response.data as List)
        .map((e) => PartsCatalogResponseDto.fromJson(e))
        .toList();
  }

  /// GET /api/parts/all - Получение всех запчастей
  Future<List<PartsCatalogResponseDto>> getAllParts() async {
    final response = await _dio.get('/api/parts/all');
    return (response.data as List)
        .map((e) => PartsCatalogResponseDto.fromJson(e))
        .toList();
  }

  // ============================================
  // WORK LOG ENDPOINTS
  // ============================================

  /// POST /api/worklogs - Создание рабочего журнала
  Future<WorkLogDto> createWorkLog(WorkLogDto workLog) async {
    final response = await _dio.post('/api/worklogs/', data: workLog.toJson());
    return WorkLogDto.fromJson(response.data);
  }

  /// GET /api/worklogs/{id} - Получение рабочего журнала по ID
  Future<WorkLogDto> getWorkLog(int id) async {
    final response = await _dio.get('/api/worklogs/$id');
    return WorkLogDto.fromJson(response.data);
  }

  /// PUT /api/worklogs/{id} - Обновление рабочего журнала
  Future<WorkLogDto> updateWorkLog(int id, WorkLogDto workLog) async {
    final response = await _dio.put('/api/worklogs/$id', data: workLog.toJson());
    return WorkLogDto.fromJson(response.data);
  }

  /// DELETE /api/worklogs/{id} - Удаление рабочего журнала
  Future<void> deleteWorkLog(int id) async {
    await _dio.delete('/api/worklogs/$id');
  }

  /// POST /api/worklogs/search - Поиск рабочих журналов
  Future<PageResponse<WorkLogDto>> searchWorkLogs(WorkLogSearchDto searchDto) async {
    final response = await _dio.post('/api/worklogs/search', data: searchDto.toJson());
    return PageResponse<WorkLogDto>.fromJson(
      response.data,
      (json) => WorkLogDto.fromJson(json),
    );
  }

  // ============================================
  // SERVICE HISTORY ENDPOINTS
  // ============================================

  /// POST /api/service-history - Создание записи истории обслуживания
  Future<ServiceHistoryDto> createServiceHistory(ServiceHistoryDto serviceHistory) async {
    final response = await _dio.post('/api/service-history/', data: serviceHistory.toJson());
    return ServiceHistoryDto.fromJson(response.data);
  }

  /// GET /api/service-history/{id} - Получение истории обслуживания по ID
  Future<ServiceHistoryDto> getServiceHistory(int id) async {
    final response = await _dio.get('/api/service-history/$id');
    return ServiceHistoryDto.fromJson(response.data);
  }

  /// GET /api/service-history/club/{clubId} - Получение истории обслуживания клуба
  Future<List<ServiceHistoryDto>> getServiceHistoryByClub(int clubId) async {
    final response = await _dio.get('/api/service-history/club/$clubId');
    return (response.data as List)
        .map((e) => ServiceHistoryDto.fromJson(e))
        .toList();
  }

  // ============================================
  // ADMIN ENDPOINTS
  // ============================================

  /// PUT /api/admin/users/{userId}/verify - Верификация пользователя
  Future<void> verifyUser(int userId) async {
    await _dio.put('/api/admin/users/$userId/verify', data: {});
  }

  /// PUT /api/admin/users/{userId}/activate - Активация пользователя
  Future<void> activateUser(int userId) async {
    await _dio.put('/api/admin/users/$userId/activate', data: {});
  }

  /// PUT /api/admin/users/{userId}/deactivate - Деактивация пользователя
  Future<void> deactivateUser(int userId) async {
    await _dio.put('/api/admin/users/$userId/deactivate', data: {});
  }

  /// DELETE /api/admin/users/{userId}/reject - Отклонение регистрации
  Future<void> rejectRegistration(int userId) async {
    await _dio.delete('/api/admin/users/$userId/reject');
  }

  // ============================================
  // INVITATION ENDPOINTS
  // ============================================

  /// POST /api/invitations/club/{clubId}/mechanic/{mechanicId} - Приглашение механика
  Future<void> inviteMechanic(int clubId, int mechanicId) async {
    await _dio.post('/api/invitations/club/$clubId/mechanic/$mechanicId', data: {});
  }

  /// PUT /api/invitations/{invitationId}/accept - Принятие приглашения
  Future<void> acceptInvitation(int invitationId) async {
    await _dio.put('/api/invitations/$invitationId/accept', data: {});
  }

  /// PUT /api/invitations/{invitationId}/reject - Отклонение приглашения
  Future<void> rejectInvitation(int invitationId) async {
    await _dio.put('/api/invitations/$invitationId/reject', data: {});
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Сохранение токенов после успешной авторизации
  Future<void> saveTokens(LoginResponseDto loginResponse) async {
    await _core.setToken(loginResponse.accessToken);
    await _core.setRefreshToken(loginResponse.refreshToken);
  }

  /// Очистка токенов при выходе
  Future<void> clearTokens() async {
    await _core.clearToken();
  }
}
