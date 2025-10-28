import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/knowledge_base/data/knowledge_base_repository.dart';
import '../../features/knowledge_base/domain/kb_pdf.dart';
import '../../features/search/domain/search_item.dart';
import '../../models/club_summary_dto.dart';
import '../../models/maintenance_request_response_dto.dart';
import '../../models/parts_catalog_response_dto.dart';
import '../repositories/club_staff_repository.dart';
import '../repositories/clubs_repository.dart';
import '../repositories/maintenance_repository.dart';
import '../repositories/parts_repository.dart';

abstract class SearchService {
  Future<SearchResultPage> searchAll(String query, {int page = 1});
  Future<SearchResultPage> searchByDomain(SearchDomain domain, String query, {int page = 1});
  void cancelActive();
  Future<MaintenanceRequestResponseDto?> getOrderById(String id);
  Future<PartsCatalogResponseDto?> getPartById(String id);
  Future<ClubSummaryDto?> getClubById(String id);
  Future<KbPdf?> getDocumentById(String id);
  Future<SearchUser?> getUserById(String id);
}

class SearchServiceImpl implements SearchService {
  SearchServiceImpl({
    MaintenanceRepository? maintenanceRepository,
    PartsRepository? partsRepository,
    ClubsRepository? clubsRepository,
    KnowledgeBaseRepository? knowledgeBaseRepository,
    ClubStaffRepository? clubStaffRepository,
  })  : _maintenanceRepository = maintenanceRepository ?? MaintenanceRepository(),
        _partsRepository = partsRepository ?? PartsRepository(),
        _clubsRepository = clubsRepository ?? ClubsRepository(),
        _knowledgeBaseRepository = knowledgeBaseRepository ?? KnowledgeBaseRepository(),
        _clubStaffRepository = clubStaffRepository ?? ClubStaffRepository();

  static const _pageSize = 20;

  final MaintenanceRepository _maintenanceRepository;
  final PartsRepository _partsRepository;
  final ClubsRepository _clubsRepository;
  final KnowledgeBaseRepository _knowledgeBaseRepository;
  final ClubStaffRepository _clubStaffRepository;

  CancelToken? _partsCancelToken;

  List<MaintenanceRequestResponseDto>? _ordersCache;
  final Map<String, List<PartsCatalogResponseDto>> _partsCache = {};
  List<ClubSummaryDto>? _clubsCache;
  List<KbPdf>? _knowledgeCache;
  List<SearchUser>? _usersCache;

  @override
  void cancelActive() {
    if (_partsCancelToken != null && !_partsCancelToken!.isCancelled) {
      _partsCancelToken!.cancel('cancelled');
    }
    _partsCancelToken = null;
  }

  @override
  Future<SearchResultPage> searchAll(String query, {int page = 1}) async {
    final trimmed = query.trim();
    final items = <SearchItem>[];
    var total = 0;

    for (final domain in SearchDomain.values) {
      if (domain == SearchDomain.all) continue;
      final result = await searchByDomain(domain, trimmed, page: 1);
      total += result.totalCount;
      items.addAll(result.items);
    }

    final sorted = _sortCombined(items, trimmed);
    final paged = _paginate(sorted, page);
    final hasMore = sorted.length > page * _pageSize;
    return SearchResultPage(
      items: paged,
      page: page,
      hasMore: hasMore,
      totalCount: total,
    );
  }

  @override
  Future<SearchResultPage> searchByDomain(SearchDomain domain, String query, {int page = 1}) async {
    switch (domain) {
      case SearchDomain.all:
        return searchAll(query, page: page);
      case SearchDomain.orders:
        return _searchOrders(query, page: page);
      case SearchDomain.parts:
        return _searchParts(query, page: page);
      case SearchDomain.clubs:
        return _searchClubs(query, page: page);
      case SearchDomain.knowledge:
        return _searchKnowledge(query, page: page);
      case SearchDomain.users:
        return _searchUsers(query, page: page);
    }
  }

  Future<SearchResultPage> _searchOrders(String query, {required int page}) async {
    _ordersCache ??= await _maintenanceRepository.getAllRequests();
    final orders = _ordersCache ?? const [];
    final filtered = orders
        .where((order) => _matchesQuery(query, [
              order.requestId.toString(),
              order.clubName,
              order.mechanicName,
              order.status,
              order.managerNotes,
            ]))
        .toList()
      ..sort((a, b) {
        final lhs = a.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rhs = b.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rhs.compareTo(lhs);
      });

    final items = _paginate(filtered, page)
        .map(
          (order) => SearchItem(
            domain: SearchDomain.orders,
            id: order.requestId.toString(),
            title: 'Заявка №${order.requestId}',
            subtitle: _buildOrderSubtitle(order),
            trailing: order.status,
            highlight: query,
          ),
        )
        .toList();

    final hasMore = filtered.length > page * _pageSize;
    return SearchResultPage(
      items: items,
      page: page,
      hasMore: hasMore,
      totalCount: filtered.length,
    );
  }

  Future<SearchResultPage> _searchParts(String query, {required int page}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const SearchResultPage(items: [], page: 1, hasMore: false, totalCount: 0);
    }

    List<PartsCatalogResponseDto>? list = _partsCache[normalized];
    if (list == null) {
      _partsCancelToken = CancelToken();
      try {
        list = await _partsRepository.search(normalized, cancelToken: _partsCancelToken);
        _partsCache[normalized] = list;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          throw SearchCancelledException();
        }
        rethrow;
      } finally {
        _partsCancelToken = null;
      }
    }

    final filtered = list
        .where((part) => _matchesQuery(normalized, [
              part.catalogNumber,
              part.commonName,
              part.officialNameRu,
              part.officialNameEn,
              part.manufacturerName,
            ]))
        .toList()
      ..sort((a, b) => a.catalogNumber.compareTo(b.catalogNumber));

    final items = _paginate(filtered, page)
        .map(
          (part) => SearchItem(
            domain: SearchDomain.parts,
            id: part.catalogNumber,
            title: _resolvePartTitle(part),
            subtitle: part.manufacturerName ?? 'Каталог #${part.catalogId}',
            trailing: part.catalogNumber,
            highlight: normalized,
          ),
        )
        .toList();

    final hasMore = filtered.length > page * _pageSize;
    return SearchResultPage(
      items: items,
      page: page,
      hasMore: hasMore,
      totalCount: filtered.length,
    );
  }

  Future<SearchResultPage> _searchClubs(String query, {required int page}) async {
    _clubsCache ??= await _clubsRepository.getClubs();
    final clubs = _clubsCache ?? const [];
    final filtered = clubs
        .where((club) => _matchesQuery(query, [club.name, club.city, club.address, club.contactPhone]))
        .toList()
      ..sort((a, b) => a.name?.compareTo(b.name ?? '') ?? 0);

    final items = _paginate(filtered, page)
        .map(
          (club) => SearchItem(
            domain: SearchDomain.clubs,
            id: club.id.toString(),
            title: club.name ?? 'Клуб #${club.id}',
            subtitle: _clubSubtitle(club),
            trailing: club.contactPhone,
            highlight: query,
          ),
        )
        .toList();

    final hasMore = filtered.length > page * _pageSize;
    return SearchResultPage(
      items: items,
      page: page,
      hasMore: hasMore,
      totalCount: filtered.length,
    );
  }

  Future<SearchResultPage> _searchKnowledge(String query, {required int page}) async {
    _knowledgeCache ??= await _knowledgeBaseRepository.load();
    final docs = _knowledgeCache ?? const [];
    final filtered = docs
        .where((doc) => _matchesQuery(query, [doc.title, doc.url, doc.serviceId?.toString()]))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final items = _paginate(filtered, page)
        .map(
          (doc) => SearchItem(
            domain: SearchDomain.knowledge,
            id: doc.url,
            title: doc.title,
            subtitle: 'Документ клуба #${doc.clubId}',
            trailing: null,
            highlight: query,
          ),
        )
        .toList();

    final hasMore = filtered.length > page * _pageSize;
    return SearchResultPage(
      items: items,
      page: page,
      hasMore: hasMore,
      totalCount: filtered.length,
    );
  }

  Future<SearchResultPage> _searchUsers(String query, {required int page}) async {
    _usersCache ??= await _loadUsers();
    final users = _usersCache ?? const [];
    final filtered = users
        .where((user) => _matchesQuery(query, [user.name, user.phone, user.roleLabel, user.clubName]))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final items = _paginate(filtered, page)
        .map(
          (user) => SearchItem(
            domain: SearchDomain.users,
            id: user.id,
            title: user.name,
            subtitle: '${user.roleLabel} · ${user.clubName}',
            trailing: user.phone,
            highlight: query,
          ),
        )
        .toList();

    final hasMore = filtered.length > page * _pageSize;
    return SearchResultPage(
      items: items,
      page: page,
      hasMore: hasMore,
      totalCount: filtered.length,
    );
  }

  List<T> _paginate<T>(List<T> data, int page) {
    if (page < 1 || data.isEmpty) {
      return const [];
    }
    final start = (page - 1) * _pageSize;
    if (start >= data.length) {
      return const [];
    }
    final end = min(start + _pageSize, data.length);
    return data.sublist(start, end);
  }

  List<SearchItem> _sortCombined(List<SearchItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    final copy = [...items];
    copy.sort((a, b) {
      final scoreA = _combinedScore(a, normalized);
      final scoreB = _combinedScore(b, normalized);
      return scoreA.compareTo(scoreB);
    });
    return copy;
  }

  int _combinedScore(SearchItem item, String query) {
    final domainRank = {
      SearchDomain.orders: 0,
      SearchDomain.parts: 1,
      SearchDomain.clubs: 2,
      SearchDomain.knowledge: 3,
      SearchDomain.users: 4,
      SearchDomain.all: 5,
    }[item.domain]!
        .toInt();

    if (query.isEmpty) {
      return domainRank * 1000;
    }
    final text = '${item.title} ${item.subtitle} ${item.trailing ?? ''}'.toLowerCase();
    final index = text.indexOf(query);
    return domainRank * 1000 + (index >= 0 ? index : 999);
  }

  String _buildOrderSubtitle(MaintenanceRequestResponseDto order) {
    final pieces = <String>[];
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      pieces.add(order.clubName!);
    }
    if (order.mechanicName != null && order.mechanicName!.isNotEmpty) {
      pieces.add(order.mechanicName!);
    }
    if (order.requestDate != null) {
      pieces.add(order.requestDate!.toIso8601String());
    }
    return pieces.isEmpty ? 'Заявка' : pieces.join(' · ');
  }

  bool _matchesQuery(String query, Iterable<String?> values) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    for (final value in values) {
      final text = value?.toLowerCase();
      if (text != null && text.contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  String _resolvePartTitle(PartsCatalogResponseDto part) {
    final candidates = [part.commonName, part.officialNameRu, part.officialNameEn];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return part.catalogNumber;
  }

  String _clubSubtitle(ClubSummaryDto club) {
    final pieces = <String>[];
    if (club.city != null && club.city!.isNotEmpty) {
      pieces.add(club.city!);
    }
    if (club.address != null && club.address!.isNotEmpty) {
      pieces.add(club.address!);
    }
    return pieces.isEmpty ? 'Клуб' : pieces.join(' · ');
  }

  Future<List<SearchUser>> _loadUsers() async {
    final clubs = await _clubsRepository.getClubs();
    final users = <SearchUser>[];
    for (final club in clubs) {
      try {
        final staff = await _clubStaffRepository.getClubStaff(club.id);
        for (final raw in staff) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw as Map);
          final name = (map['fullName'] as String? ?? '').trim();
          final phone = (map['phone'] as String? ?? '').trim();
          final role = (map['role'] as String? ?? '').trim();
          final id = '${club.id}-${(map['id'] ?? map['userId'] ?? map['user_id'] ?? name)}-${role.isEmpty ? 'STAFF' : role}';
          users.add(
            SearchUser(
              id: id,
              clubId: club.id,
              clubName: club.name ?? 'Клуб #${club.id}',
              name: name.isEmpty ? 'Без имени' : name,
              phone: phone.isEmpty ? null : phone,
              role: role.isEmpty ? 'STAFF' : role,
            ),
          );
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to load staff for club ${club.id}: $error\n$stackTrace');
      }
    }
    return users;
  }

  @override
  Future<MaintenanceRequestResponseDto?> getOrderById(String id) async {
    _ordersCache ??= await _maintenanceRepository.getAllRequests();
    final numeric = int.tryParse(id);
    if (numeric == null) return null;
    for (final order in _ordersCache ?? const []) {
      if (order.requestId == numeric) {
        return order;
      }
    }
    return null;
  }

  @override
  Future<PartsCatalogResponseDto?> getPartById(String id) async {
    for (final list in _partsCache.values) {
      for (final part in list) {
        if (part.catalogNumber == id || part.catalogId.toString() == id) {
          return part;
        }
      }
    }
    return null;
  }

  @override
  Future<ClubSummaryDto?> getClubById(String id) async {
    _clubsCache ??= await _clubsRepository.getClubs();
    final numeric = int.tryParse(id);
    for (final club in _clubsCache ?? const []) {
      if (numeric != null && club.id == numeric) {
        return club;
      }
      if (club.id.toString() == id) {
        return club;
      }
    }
    return null;
  }

  @override
  Future<KbPdf?> getDocumentById(String id) async {
    _knowledgeCache ??= await _knowledgeBaseRepository.load();
    for (final doc in _knowledgeCache ?? const []) {
      if (doc.url == id) {
        return doc;
      }
    }
    return null;
  }

  @override
  Future<SearchUser?> getUserById(String id) async {
    _usersCache ??= await _loadUsers();
    for (final user in _usersCache ?? const []) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }
}

class SearchUser {
  const SearchUser({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.name,
    required this.role,
    this.phone,
  });

  final String id;
  final int clubId;
  final String clubName;
  final String name;
  final String role;
  final String? phone;

  String get roleLabel {
    switch (role.toUpperCase()) {
      case 'MECHANIC':
        return 'Механик';
      case 'OWNER':
        return 'Владелец';
      case 'MANAGER':
        return 'Менеджер';
      case 'ADMIN':
        return 'Администратор';
      default:
        return 'Сотрудник';
    }
  }
}

class SearchCancelledException implements Exception {}

