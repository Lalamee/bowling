import '../../api/api_service.dart';
import '../../models/club_summary_dto.dart';

class ClubsRepository {
  final ApiService _apiService = ApiService();

  Future<List<ClubSummaryDto>> getClubs() async {
    final response = await _apiService.getPublicClubs();
    return response;
  }
}
