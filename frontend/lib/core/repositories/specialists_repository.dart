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

  Future<MechanicDirectoryDetail?> getDetail(int profileId) async {
    final res = await _dio.get('/api/mechanics/$profileId');
    if (res.statusCode == 200 && res.data is Map) {
      return MechanicDirectoryDetail.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }

  Future<List<AttestationApplication>> getAttestationApplications() async {
    final res = await _dio.get('/api/attestations/applications');
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
}

