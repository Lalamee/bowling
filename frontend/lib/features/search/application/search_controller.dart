import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/search_item.dart';
import '../../../core/repositories/search_repository.dart';
import '../../../core/services/search_service.dart';

class SearchController extends ChangeNotifier {
  SearchController({SearchRepository? repository})
      : _repository = repository ?? SearchRepository(),
        _state = SearchState.initial();

  final SearchRepository _repository;
  SearchState _state;
  Timer? _debounce;
  int _requestId = 0;

  static SearchState? _lastSnapshot;

  SearchState get state => _state;

  void restore() {
    if (_lastSnapshot != null) {
      _state = _lastSnapshot!;
      notifyListeners();
    }
  }

  void updateQuery(String value, {bool immediate = false}) {
    if (value == _state.query) return;
    _state = _state.copyWith(query: value, restoredFromCache: false);
    _persist();
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _repository.cancelActive();
      _state = _state.resetForQuery();
      notifyListeners();
      return;
    }
    if (immediate) {
      _runSearch(page: 1, append: false);
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _runSearch(page: 1, append: false);
      });
    }
    notifyListeners();
  }

  void selectDomain(SearchDomain domain) {
    if (domain == _state.domain) return;
    _repository.cancelActive();
    _debounce?.cancel();
    _state = _state.copyWith(
      domain: domain,
      items: const [],
      hasMore: false,
      totalCount: 0,
      page: 1,
      isLoading: false,
      isLoadingMore: false,
      hasError: false,
      errorMessage: null,
      restoredFromCache: false,
    );

    final query = _state.query.trim();
    if (query.isEmpty) {
      _persist();
      notifyListeners();
      return;
    }

    final cached = _repository.peek(domain, query, page: 1);
    if (cached != null) {
      _state = _state.copyWith(
        items: cached.items,
        hasMore: cached.hasMore,
        totalCount: cached.totalCount,
        page: cached.page,
        isLoading: false,
        restoredFromCache: true,
      );
      _persist();
      notifyListeners();
      return;
    }

    _persist();
    notifyListeners();
    _runSearch(page: 1, append: false);
  }

  Future<void> submit() async {
    _debounce?.cancel();
    await _runSearch(page: 1, append: false, force: true);
  }

  Future<void> refresh() async {
    await _runSearch(page: 1, append: false, force: true);
  }

  Future<void> loadMore() async {
    if (!_state.hasMore || _state.isLoading || _state.isLoadingMore || _state.query.trim().isEmpty) {
      return;
    }
    final nextPage = _state.page + 1;
    await _runSearch(page: nextPage, append: true);
  }

  @override
  void dispose() {
    _persist();
    _debounce?.cancel();
    _repository.cancelActive();
    super.dispose();
  }

  Future<void> _runSearch({required int page, required bool append, bool force = false}) async {
    final query = _state.query.trim();
    if (query.isEmpty) {
      _state = _state.resetForQuery();
      _persist();
      notifyListeners();
      return;
    }

    final cached = (!force) ? _repository.peek(_state.domain, query, page: page) : null;
    if (cached != null) {
      final newItems = append ? [..._state.items, ...cached.items] : [...cached.items];
      _state = _state.copyWith(
        items: newItems,
        hasMore: cached.hasMore,
        totalCount: cached.totalCount,
        page: cached.page,
        isLoading: false,
        isLoadingMore: false,
        hasError: false,
        errorMessage: null,
        restoredFromCache: true,
      );
      _persist();
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    if (append) {
      _state = _state.copyWith(isLoadingMore: true, hasError: false, errorMessage: null);
    } else {
      _state = _state.copyWith(
        isLoading: true,
        hasError: false,
        errorMessage: null,
        restoredFromCache: false,
        items: append ? _state.items : (force ? const [] : _state.items),
      );
    }
    _persist();
    notifyListeners();

    try {
      final result = await _repository.search(
        _state.domain,
        query,
        page: page,
        forceRefresh: force,
      );
      if (_requestId != requestId) {
        return;
      }
      final newItems = append ? [..._state.items, ...result.items] : [...result.items];
      _state = _state.copyWith(
        items: newItems,
        hasMore: result.hasMore,
        totalCount: result.totalCount,
        page: result.page,
        isLoading: false,
        isLoadingMore: false,
        hasError: false,
        errorMessage: null,
        restoredFromCache: false,
      );
    } on SearchCancelledException {
      return;
    } catch (error) {
      if (_requestId != requestId) {
        return;
      }
      _state = _state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasError: true,
        errorMessage: error.toString(),
      );
    } finally {
      if (_requestId == requestId) {
        _persist();
        notifyListeners();
      }
    }
  }

  void _persist() {
    _lastSnapshot = _state;
  }
}

class SearchState {
  final SearchDomain domain;
  final String query;
  final List<SearchItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final int page;
  final int totalCount;
  final bool restoredFromCache;

  const SearchState({
    required this.domain,
    required this.query,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasError,
    required this.errorMessage,
    required this.hasMore,
    required this.page,
    required this.totalCount,
    required this.restoredFromCache,
  });

  factory SearchState.initial() => const SearchState(
        domain: SearchDomain.all,
        query: '',
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasError: false,
        errorMessage: null,
        hasMore: false,
        page: 1,
        totalCount: 0,
        restoredFromCache: false,
      );

  SearchState copyWith({
    SearchDomain? domain,
    String? query,
    List<SearchItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    int? page,
    int? totalCount,
    bool? restoredFromCache,
  }) {
    return SearchState(
      domain: domain ?? this.domain,
      query: query ?? this.query,
      items: List<SearchItem>.unmodifiable(items ?? this.items),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      restoredFromCache: restoredFromCache ?? this.restoredFromCache,
    );
  }

  SearchState resetForQuery() {
    return copyWith(
      items: const [],
      hasMore: false,
      totalCount: 0,
      page: 1,
      isLoading: false,
      isLoadingMore: false,
      hasError: false,
      errorMessage: null,
      restoredFromCache: false,
    );
  }

  bool get isIdle => query.trim().isEmpty && items.isEmpty && !isLoading && !hasError;
  bool get isEmpty => query.trim().isNotEmpty && items.isEmpty && !isLoading && !hasError;
}

