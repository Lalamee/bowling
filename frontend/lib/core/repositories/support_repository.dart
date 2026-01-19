import '../../api/api_service.dart';
import '../../models/support_appeal_request_dto.dart';

class SupportRepository {
  final ApiService _api = ApiService();

  Future<void> submitAppeal(SupportAppealRequestDto request) async {
    await _api.submitSupportAppeal(request);
  }
}
