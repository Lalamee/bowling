import 'package:bowling_market/core/services/search_service.dart';
import 'package:bowling_market/features/knowledge_base/domain/kb_pdf.dart';
import 'package:bowling_market/features/search/domain/search_item.dart';
import 'package:bowling_market/models/club_summary_dto.dart';
import 'package:bowling_market/models/maintenance_request_response_dto.dart';
import 'package:bowling_market/models/parts_catalog_response_dto.dart';

class StubSearchService implements SearchService {
  final Map<_ServiceKey, SearchResultPage> _results = {};
  final Map<_ServiceKey, Object> _errors = {};

  void setResult(SearchDomain domain, String query, int page, SearchResultPage result) {
    _results[_ServiceKey(domain, query.trim(), page)] = result;
  }

  void throwErrorFor(SearchDomain domain, String query, int page, Object error) {
    _errors[_ServiceKey(domain, query.trim(), page)] = error;
  }

  @override
  void cancelActive() {}

  @override
  Future<SearchResultPage> searchAll(String query, {int page = 1}) {
    return searchByDomain(SearchDomain.all, query, page: page);
  }

  @override
  Future<SearchResultPage> searchByDomain(SearchDomain domain, String query, {int page = 1}) async {
    final key = _ServiceKey(domain, query.trim(), page);
    if (_errors.containsKey(key)) {
      final error = _errors[key]!;
      if (error is Exception) {
        throw error;
      }
      throw Exception(error.toString());
    }
    final result = _results[key];
    if (result != null) {
      return result;
    }
    return const SearchResultPage(items: [], page: 1, hasMore: false, totalCount: 0);
  }

  @override
  Future<MaintenanceRequestResponseDto?> getOrderById(String id) async => null;

  @override
  Future<PartsCatalogResponseDto?> getPartById(String id) async => null;

  @override
  Future<ClubSummaryDto?> getClubById(String id) async => null;

  @override
  Future<KbPdf?> getDocumentById(String id) async => null;

  @override
  Future<SearchUser?> getUserById(String id) async => null;
}

class _ServiceKey {
  _ServiceKey(this.domain, String query, this.page)
      : query = query.trim();

  final SearchDomain domain;
  final String query;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is _ServiceKey &&
        other.domain == domain &&
        other.query == query &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(domain, query, page);
}
