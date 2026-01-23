import '../../api/api_service.dart';
import '../../models/notification_event_dto.dart';
import '../../models/service_journal_entry_dto.dart';
import '../../models/technical_info_create_dto.dart';
import '../../models/technical_info_dto.dart';
import '../../models/warning_dto.dart';
import '../../models/club_appeal_request_dto.dart';

class OwnerDashboardRepository {
  final ApiService _api = ApiService();

  Future<List<TechnicalInfoDto>> technicalInfo({int? clubId}) async {
    return _api.getTechnicalInfo(clubId: clubId);
  }

  Future<TechnicalInfoDto> createTechnicalInfo(TechnicalInfoCreateDto request) async {
    return _api.createTechnicalInfo(request);
  }

  Future<List<ServiceJournalEntryDto>> serviceJournal({
    int? clubId,
    int? laneNumber,
    DateTime? start,
    DateTime? end,
    String? workType,
    String? status,
  }) async {
    return _api.getServiceJournal(
      clubId: clubId,
      laneNumber: laneNumber,
      start: start,
      end: end,
      workType: workType,
      status: status,
    );
  }

  Future<List<WarningDto>> warnings({int? clubId}) async {
    return _api.getWarnings(clubId: clubId);
  }

  Future<List<NotificationEventDto>> managerNotifications({int? clubId, String? role}) async {
    return _api.getManagerNotifications(clubId: clubId, role: role);
  }

  Future<void> submitClubAppeal(ClubAppealRequestDto request) async {
    await _api.submitClubAppeal(request);
  }
}
