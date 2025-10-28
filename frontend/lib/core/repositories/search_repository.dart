import 'package:flutter/foundation.dart';

import '../../features/knowledge_base/domain/kb_pdf.dart';
import '../../features/search/domain/search_item.dart';
import '../../models/club_summary_dto.dart';
import '../../models/maintenance_request_response_dto.dart';
import '../../models/parts_catalog_response_dto.dart';
import '../services/search_service.dart';

class SearchRepository {
  SearchRepository({SearchService? service})
      : _service = service ?? SearchServiceImpl();

  final SearchService _service;
  final Map<_CacheKey, SearchResultPage> _cache = {};

  Future<SearchResultPage> search(
    SearchDomain domain,
    String query, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final normalized = query.trim();
    final key = _CacheKey(domain, normalized.toLowerCase(), page);

    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null) {
        return cached;
      }
    }

    final stopwatch = Stopwatch()..start();
    debugPrint('SearchStarted domain=${domain.name} query="$normalized" page=$page');
    try {
      final result = await _service.searchByDomain(domain, normalized, page: page);
      _cache[key] = result;
      debugPrint(
        'SearchFinished domain=${domain.name} query="$normalized" page=$page count=${result.items.length} total=${result.totalCount} durationMs=${stopwatch.elapsedMilliseconds}',
      );
      return result;
    } on SearchCancelledException {
      debugPrint('SearchCancelled domain=${domain.name} query="$normalized" page=$page');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        'SearchFailed domain=${domain.name} query="$normalized" page=$page error=$error\n$stackTrace',
      );
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  SearchResultPage? peek(SearchDomain domain, String query, {int page = 1}) {
    final key = _CacheKey(domain, query.trim().toLowerCase(), page);
    return _cache[key];
  }

  void cancelActive() {
    _service.cancelActive();
  }

  void clearCache() {
    _cache.clear();
  }

  Future<MaintenanceRequestResponseDto?> getOrderById(String id) {
    return _service.getOrderById(id);
  }

  Future<PartsCatalogResponseDto?> getPartById(String id) {
    return _service.getPartById(id);
  }

  Future<ClubSummaryDto?> getClubById(String id) {
    return _service.getClubById(id);
  }

  Future<KbPdf?> getDocumentById(String id) {
    return _service.getDocumentById(id);
  }

  Future<SearchUser?> getUserById(String id) {
    return _service.getUserById(id);
  }
}

class _CacheKey {
  const _CacheKey(this.domain, this.query, this.page);

  final SearchDomain domain;
  final String query;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is _CacheKey &&
        other.domain == domain &&
        other.query == query &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(domain, query, page);
}

