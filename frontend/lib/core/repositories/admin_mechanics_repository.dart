import '../../api/api_core.dart';

class AdminMechanicsOverview {
  final List<dynamic> pending;
  final List<dynamic> clubs;

  AdminMechanicsOverview({required this.pending, required this.clubs});

  factory AdminMechanicsOverview.empty() => AdminMechanicsOverview(pending: const [], clubs: const []);

  factory AdminMechanicsOverview.fromJson(Map<String, dynamic> json) {
    final pendingRaw = json['pending'];
    final clubsRaw = json['clubs'];
    return AdminMechanicsOverview(
      pending: pendingRaw is List ? List<dynamic>.from(pendingRaw) : const [],
      clubs: clubsRaw is List ? List<dynamic>.from(clubsRaw) : const [],
    );
  }
}

class AdminMechanicsRepository {
  final _dio = ApiCore().dio;

  Future<AdminMechanicsOverview> getOverview() async {
    final res = await _dio.get('/api/admin/mechanics');
    if (res.statusCode == 200 && res.data is Map) {
      return AdminMechanicsOverview.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return AdminMechanicsOverview.empty();
  }
}
