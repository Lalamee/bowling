import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../api/api_core.dart';
import '../../../core/repositories/maintenance_repository.dart';
import '../../../core/repositories/service_history_repository.dart';
import '../../../models/maintenance_request_response_dto.dart';
import '../../../models/service_history_dto.dart';
import '../domain/kb_pdf.dart';

class KnowledgeBaseRepository {
  KnowledgeBaseRepository({
    MaintenanceRepository? maintenanceRepository,
    ServiceHistoryRepository? serviceHistoryRepository,
    Dio? dio,
  })  : _maintenanceRepository = maintenanceRepository ?? MaintenanceRepository(),
        _serviceHistoryRepository = serviceHistoryRepository ?? ServiceHistoryRepository(),
        _dio = dio ?? ApiCore().dio;

  final MaintenanceRepository _maintenanceRepository;
  final ServiceHistoryRepository _serviceHistoryRepository;
  final Dio _dio;

  Future<List<KbPdf>> load() async {
    final requests = await _maintenanceRepository.getAllRequests();
    final clubIds = _collectClubIds(requests);

    if (clubIds.isEmpty) {
      return const [];
    }

    final documents = <KbPdf>[];
    for (final clubId in clubIds) {
      final historyRecords = await _serviceHistoryRepository.getByClub(clubId);
      documents.addAll(_mapHistoryToDocuments(clubId, historyRecords));
    }

    // remove duplicates by url
    final seen = <String>{};
    final unique = <KbPdf>[];
    for (final doc in documents) {
      final key = doc.url;
      if (seen.add(key)) {
        unique.add(doc);
      }
    }

    return unique;
  }

  Future<Uint8List> fetchDocument(String url) async {
    final resolved = _resolveUrl(url);
    final response = await _dio.get<List<int>>(
      resolved,
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;
    if (data == null) {
      throw ApiException('Не удалось загрузить документ');
    }
    return Uint8List.fromList(data);
  }

  Set<int> _collectClubIds(List<MaintenanceRequestResponseDto> requests) {
    final ids = <int>{};
    for (final request in requests) {
      final clubId = request.clubId;
      if (clubId != null) {
        ids.add(clubId);
      }
    }
    return ids;
  }

  Iterable<KbPdf> _mapHistoryToDocuments(
    int clubId,
    List<ServiceHistoryDto> historyRecords,
  ) {
    final items = <KbPdf>[];
    for (final record in historyRecords) {
      final documents = record.documents ?? const <String>[];
      if (documents.isEmpty) {
        continue;
      }

      final title = _buildTitle(record);
      for (final documentUrl in documents) {
        final resolvedUrl = _resolveUrl(documentUrl);
        items.add(
          KbPdf(
            title: title,
            url: resolvedUrl,
            clubId: clubId,
            serviceId: record.serviceId,
          ),
        );
      }
    }
    return items;
  }

  String _buildTitle(ServiceHistoryDto record) {
    if (record.equipmentName != null && record.equipmentName!.isNotEmpty) {
      return record.equipmentName!;
    }
    if (record.description.isNotEmpty) {
      return record.description;
    }
    return 'Документ обслуживания';
  }

  String _resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = ApiCore().baseUrl;
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }
}
