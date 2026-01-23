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
import '../models/free_mechanic_application_request_dto.dart';
import '../models/free_mechanic_application_response_dto.dart';
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
import '../models/stock_issue_decision_dto.dart';
import '../models/close_request_dto.dart';
import '../models/equipment_component_dto.dart';
import '../models/equipment_category_dto.dart';
import '../models/club_summary_dto.dart';
import '../models/club_create_dto.dart';
import '../models/purchase_order_summary_dto.dart';
import '../models/purchase_order_detail_dto.dart';
import '../models/purchase_order_acceptance_request_dto.dart';
import '../models/supplier_review_request_dto.dart';
import '../models/supplier_complaint_request_dto.dart';
import '../models/supplier_complaint_status_update_dto.dart';
import '../models/technical_info_dto.dart';
import '../models/service_journal_entry_dto.dart';
import '../models/warning_dto.dart';
import '../models/notification_event_dto.dart';
import '../models/help_request_dto.dart';
import '../models/admin_help_request_dto.dart';
import '../models/admin_registration_application_dto.dart';
import '../models/admin_account_update_dto.dart';
import '../models/mechanic_club_link_request_dto.dart';
import '../models/admin_complaint_dto.dart';
import '../models/admin_appeal_dto.dart';
import '../models/admin_mechanic_status_change_dto.dart';
import '../models/admin_staff_status_update_dto.dart';
import '../models/admin_mechanic_account_change_dto.dart';
import '../models/club_appeal_request_dto.dart';
import '../models/support_appeal_request_dto.dart';

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

  /// POST /api/auth/free-mechanics/apply - Регистрация свободного механика
  Future<FreeMechanicApplicationResponseDto> applyFreeMechanic(
      FreeMechanicApplicationRequestDto request) async {
    final response = await _dio.post('/api/auth/free-mechanics/apply', data: request.toJson());
    return FreeMechanicApplicationResponseDto.fromJson(response.data);
  }

  /// GET /api/public/clubs - Получение списка клубов
  Future<List<ClubSummaryDto>> getPublicClubs() async {
    final response = await _dio.get('/api/public/clubs');
    return (response.data as List)
        .map((e) => ClubSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/admin/clubs - Добавление клуба администратором
  Future<ClubSummaryDto> createClub(ClubCreateDto request) async {
    final response = await _dio.post('/api/admin/clubs', data: request.toJson());
    return ClubSummaryDto.fromJson(response.data as Map<String, dynamic>);
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

  /// PATCH /api/requests/{id}/stock-issue - Частичное согласование и выдача со склада
  Future<MaintenanceRequestResponseDto> issueFromStock(
    int id,
    StockIssueDecisionDto request,
  ) async {
    final response = await _dio.patch('/api/requests/$id/stock-issue', data: request.toJson());
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

  /// POST /api/maintenance/requests/{id}/help - Запрос помощи механика
  Future<MaintenanceRequestResponseDto> requestHelp(int id, HelpRequestDto request) async {
    final response = await _dio.post(
      '/api/maintenance/requests/$id/help',
      data: request.toJson(),
    );
    return MaintenanceRequestResponseDto.fromJson(response.data);
  }

  /// POST /api/maintenance/requests/{id}/help/decision - Ответ менеджера/админа на запрос помощи
  Future<MaintenanceRequestResponseDto> resolveHelp(int id, HelpResponseDto request) async {
    final response = await _dio.post(
      '/api/maintenance/requests/$id/help/decision',
      data: request.toJson(),
    );
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

  /// GET /api/admin/help-requests - Список запросов помощи для Администрации
  Future<List<AdminHelpRequestDto>> getAdminHelpRequests() async {
    final response = await _dio.get('/api/admin/help-requests');
    return (response.data as List)
        .map((e) => AdminHelpRequestDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/admin/free-mechanics/applications - заявки и аккаунты свободных механиков
  Future<List<FreeMechanicApplicationResponseDto>> listFreeMechanicApplications() async {
    final response = await _dio.get('/api/admin/free-mechanics/applications');
    return (response.data as List)
        .map(
          (e) => FreeMechanicApplicationResponseDto.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// GET /api/admin/registrations - заявки на регистрацию
  Future<List<AdminRegistrationApplicationDto>> getAdminRegistrations() async {
    final response = await _dio.get('/api/admin/registrations');
    return (response.data as List)
        .map((e) => AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/admin/appeals - обращения и оповещения для Администрации
  Future<List<AdminAppealDto>> listAdminAppeals() async {
    final response = await _dio.get('/api/admin/appeals');
    return (response.data as List)
        .map((e) => AdminAppealDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// POST /api/admin/registrations/{userId}/approve - утверждение регистрации
  Future<AdminRegistrationApplicationDto> approveRegistration(int userId) async {
    final response = await _dio.post('/api/admin/registrations/$userId/approve');
    return AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// POST /api/admin/registrations/{userId}/reject - отклонение с причиной
  Future<AdminRegistrationApplicationDto> rejectRegistration(int userId, {String? reason}) async {
    final response = await _dio.post(
      '/api/admin/registrations/$userId/reject',
      data: reason ?? '',
    );
    return AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// PATCH /api/admin/free-mechanics/{userId}/account - обновление аккаунта свободного механика
  Future<AdminRegistrationApplicationDto> updateFreeMechanicAccount(
    int userId,
    AdminAccountUpdateDto request,
  ) async {
    final response = await _dio.patch(
      '/api/admin/free-mechanics/$userId/account',
      data: request.toJson(),
    );
    return AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// PATCH /api/admin/mechanics/{userId}/account - перевод между клубным/свободным форматами
  Future<AdminRegistrationApplicationDto> convertMechanicAccount(
    int userId,
    AdminMechanicAccountChangeDto change,
  ) async {
    final response = await _dio.patch(
      '/api/admin/mechanics/$userId/account',
      data: change.toJson(),
    );
    return AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// PATCH /api/admin/mechanics/{profileId}/clubs - привязка/отвязка механика
  Future<AdminRegistrationApplicationDto> changeMechanicClubLink(
    int profileId,
    MechanicClubLinkRequestDto request,
  ) async {
    final response = await _dio.patch(
      '/api/admin/mechanics/$profileId/clubs',
      data: request.toJson(),
    );
    return AdminRegistrationApplicationDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// GET /api/admin/supplier-complaints - список споров с поставщиками
  Future<List<AdminComplaintDto>> getSupplierComplaints() async {
    final response = await _dio.get('/api/admin/supplier-complaints');
    return (response.data as List)
        .map((e) => AdminComplaintDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// PATCH /api/admin/supplier-complaints/{reviewId} - обновление статуса спора
  Future<AdminComplaintDto> updateSupplierComplaint({
    required int reviewId,
    String? status,
    bool? resolved,
    String? notes,
  }) async {
    final response = await _dio.patch(
      '/api/admin/supplier-complaints/$reviewId',
      queryParameters: {
        if (status != null) 'status': status,
        if (resolved != null) 'resolved': resolved,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return AdminComplaintDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // ============================================
  // PURCHASE ORDERS
  // ============================================

  Future<List<PurchaseOrderSummaryDto>> getPurchaseOrders({
    int? clubId,
    bool archived = false,
    String? status,
    bool? hasComplaint,
    bool? hasReview,
    String? supplier,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get(
      '/api/purchase-orders',
      queryParameters: {
        if (clubId != null) 'clubId': clubId,
        'archived': archived,
        if (status != null) 'status': status,
        if (hasComplaint != null) 'hasComplaint': hasComplaint,
        if (hasReview != null) 'hasReview': hasReview,
        if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    return (response.data as List)
        .map((e) => PurchaseOrderSummaryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/admin/staff/status-requests - заявки на изменение статуса/доступа механиков
  Future<List<AdminMechanicStatusChangeDto>> listMechanicStatusChanges() async {
    final response = await _dio.get('/api/admin/staff/status-requests');
    return (response.data as List)
        .map((e) => AdminMechanicStatusChangeDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// PATCH /api/admin/staff/{staffId}/status - изменить активность/доступ к данным
  Future<AdminMechanicStatusChangeDto> updateMechanicStatus({required int staffId, required AdminStaffStatusUpdateDto update}) async {
    final response = await _dio.patch(
      '/api/admin/staff/$staffId/status',
      data: update.toJson(),
    );
    return AdminMechanicStatusChangeDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<PurchaseOrderDetailDto> getPurchaseOrder(int orderId) async {
    final response = await _dio.get('/api/purchase-orders/$orderId');
    return PurchaseOrderDetailDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<PurchaseOrderDetailDto> acceptPurchaseOrder(
    int orderId,
    PurchaseOrderAcceptanceRequestDto request,
  ) async {
    final response = await _dio.post(
      '/api/purchase-orders/$orderId/acceptance',
      data: request.toJson(),
    );
    return PurchaseOrderDetailDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<PurchaseOrderDetailDto> reviewPurchaseOrder(
    int orderId,
    SupplierReviewRequestDto request,
  ) async {
    final response = await _dio.post(
      '/api/purchase-orders/$orderId/reviews',
      data: request.toJson(),
    );
    return PurchaseOrderDetailDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<PurchaseOrderDetailDto> complainPurchaseOrder(
    int orderId,
    SupplierComplaintRequestDto request,
  ) async {
    final response = await _dio.post(
      '/api/purchase-orders/$orderId/complaints',
      data: request.toJson(),
    );
    return PurchaseOrderDetailDto.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<PurchaseOrderDetailDto> updateComplaintStatus(
    int orderId,
    int reviewId,
    SupplierComplaintStatusUpdateDto request,
  ) async {
    final response = await _dio.patch(
      '/api/purchase-orders/$orderId/complaints/$reviewId',
      data: request.toJson(),
    );
    return PurchaseOrderDetailDto.fromJson(Map<String, dynamic>.from(response.data as Map));
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

  /// GET /api/equipment/categories - Получение иерархии категорий оборудования
  Future<List<EquipmentCategoryDto>> getEquipmentCategories({
    String? brand,
    int? parentId,
    int? level,
  }) async {
    final response = await _dio.get('/api/equipment/categories', queryParameters: {
      if (brand != null) 'brand': brand,
      if (parentId != null) 'parentId': parentId,
      if (level != null) 'level': level,
    });

    return (response.data as List)
        .map((e) => EquipmentCategoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/equipment/components - Получение дерева узлов оборудования
  Future<List<EquipmentComponentDto>> getEquipmentComponents({int? parentId}) async {
    final response = await _dio.get('/api/equipment/components', queryParameters: {
      if (parentId != null) 'parentId': parentId,
    });
    return (response.data as List)
        .map((e) => EquipmentComponentDto.fromJson(Map<String, dynamic>.from(e as Map)))
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
  // OWNER/MANAGER DASHBOARD ENDPOINTS
  // ============================================

  Future<List<TechnicalInfoDto>> getTechnicalInfo({int? clubId}) async {
    final response = await _dio.get(
      '/api/owner-dashboard/technical-info',
      queryParameters: clubId != null ? {'clubId': clubId} : null,
    );
    return (response.data as List)
        .map((e) => TechnicalInfoDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ServiceJournalEntryDto>> getServiceJournal({
    int? clubId,
    int? laneNumber,
    DateTime? start,
    DateTime? end,
    String? workType,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (clubId != null) params['clubId'] = clubId;
    if (laneNumber != null) params['laneNumber'] = laneNumber;
    if (start != null) params['start'] = start.toIso8601String();
    if (end != null) params['end'] = end.toIso8601String();
    if (workType != null && workType.isNotEmpty) params['workType'] = workType;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _dio.get('/api/owner-dashboard/service-history', queryParameters: params);
    return (response.data as List)
        .map((e) => ServiceJournalEntryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<WarningDto>> getWarnings({int? clubId}) async {
    final response = await _dio.get(
      '/api/owner-dashboard/warnings',
      queryParameters: clubId != null ? {'clubId': clubId} : null,
    );
    return (response.data as List)
        .map((e) => WarningDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<NotificationEventDto>> getManagerNotifications({int? clubId, String? role}) async {
    final params = <String, dynamic>{};
    if (clubId != null) params['clubId'] = clubId;
    if (role != null && role.isNotEmpty) params['role'] = role;

    final response = await _dio.get('/api/owner-dashboard/notifications', queryParameters: params);
    return (response.data as List)
        .map((e) => NotificationEventDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// POST /api/owner-dashboard/appeals - обращение клуба в администрацию
  Future<void> submitClubAppeal(ClubAppealRequestDto request) async {
    await _dio.post('/api/owner-dashboard/appeals', data: request.toJson());
  }

  /// POST /api/support/appeals - обращение пользователя в администрацию
  Future<void> submitSupportAppeal(SupportAppealRequestDto request) async {
    await _dio.post('/api/support/appeals', data: request.toJson());
  }

  /// POST /api/admin/appeals/{appealId}/reply - ответ администрации на обращение
  Future<void> replyToAppeal({required String appealId, required String message}) async {
    await _dio.post('/api/admin/appeals/$appealId/reply', data: {'message': message});
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
