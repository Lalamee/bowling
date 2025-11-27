import '../../api/api_service.dart';
import '../../models/notification_event_dto.dart';
import '../../models/service_journal_entry_dto.dart';
import '../../models/technical_info_dto.dart';
import '../../models/warning_dto.dart';

class OwnerDashboardRepository {
  final ApiService _api = ApiService();

  Future<List<TechnicalInfoDto>> technicalInfo({int? clubId}) async {
    return _api.getTechnicalInfo(clubId: clubId);
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
}
