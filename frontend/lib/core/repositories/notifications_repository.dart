import '../../api/api_service.dart';
import '../../models/notification_event_dto.dart';

class NotificationsRepository {
  final ApiService _api = ApiService();

  Future<List<NotificationEventDto>> fetchNotifications({int? clubId, String? role}) async {
    return _api.getManagerNotifications(clubId: clubId, role: role);
  }
}
