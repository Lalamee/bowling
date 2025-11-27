import '../../api/api_core.dart';
import '../../models/mechanic_directory_models.dart';

class SpecialistsRepository {
  final _dio = ApiCore().dio;

  Future<List<MechanicDirectoryItem>> search({String? query, String? region, String? certification}) async {
    final res = await _dio.get('/api/mechanics', queryParameters: {
      if (query != null && query.trim().isNotEmpty) 'query': query,
      if (region != null && region.trim().isNotEmpty) 'region': region,
      if (certification != null && certification.trim().isNotEmpty) 'certification': certification,
    });

    final data = res.data;
    if (res.statusCode == 200 && data is List) {
      return data
          .whereType<Map>()
          .map((e) => MechanicDirectoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<List<SpecialistCard>> specialistBase({String? region, int? specializationId, MechanicGrade? grade, double? minRating}) async {
    final res = await _dio.get('/api/mechanics/specialists', queryParameters: {
      if (region != null && region.trim().isNotEmpty) 'region': region,
      if (specializationId != null) 'specializationId': specializationId,
      if (grade != null) 'grade': grade.toApiValue(),
      if (minRating != null) 'minRating': minRating,
    });

    final data = res.data;
    if (res.statusCode == 200 && data is List) {
      return data
          .whereType<Map>()
          .map((e) => SpecialistCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<MechanicDirectoryDetail?> getDetail(int profileId) async {
    final res = await _dio.get('/api/mechanics/$profileId');
    if (res.statusCode == 200 && res.data is Map) {
      return MechanicDirectoryDetail.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }

  Future<List<AttestationApplication>> getAttestationApplications({AttestationDecisionStatus? status}) async {
    final res = await _dio.get('/api/attestations/applications', queryParameters: {
      if (status != null) 'status': status.toApiValue(),
    });
    final data = res.data;
    if (res.statusCode == 200 && data is List) {
      return data
          .whereType<Map>()
          .map((e) => AttestationApplication.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<AttestationApplication?> submitAttestationApplication(AttestationApplication application) async {
    final res = await _dio.post('/api/attestations/applications', data: application.toJson());
    if (res.statusCode == 200 && res.data is Map) {
      return AttestationApplication.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }

  Future<AttestationApplication?> decideApplication({required int applicationId, required AttestationDecisionStatus status, MechanicGrade? approvedGrade, String? comment}) async {
    final payload = {
      'status': status.toApiValue(),
      if (approvedGrade != null) 'approvedGrade': approvedGrade.toApiValue(),
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment,
    };
    final res = await _dio.put('/api/attestations/applications/$applicationId/status', data: payload);
    if (res.statusCode == 200 && res.data is Map) {
      return AttestationApplication.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }
}

