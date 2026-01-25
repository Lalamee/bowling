import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/club_summary_dto.dart';
import '../../../../models/warehouse_summary_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../services/local_search_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _clubsRepository = ClubsRepository();
  final _userRepository = UserRepository();
  final _inventoryRepository = InventoryRepository();
  final _localSearchService = const LocalSearchService();

  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  bool _hasError = false;
  UserAccessScope? _scope;

  List<ClubSummaryDto> _clubsCache = const <ClubSummaryDto>[];
  List<InventorySearchEntry> _personalInventoryCache = const <InventorySearchEntry>[];
  List<InventorySearchEntry> _clubInventoryCache = const <InventorySearchEntry>[];
  List<InventorySearchEntry> _personalInventoryFiltered = const <InventorySearchEntry>[];
  List<InventorySearchEntry> _clubInventoryFiltered = const <InventorySearchEntry>[];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final responses = await Future.wait([
        _clubsRepository.getClubs(),
        _inventoryRepository.getWarehouses(),
      ]);
      if (!mounted) return;
      final rawClubs = responses[0] as List<ClubSummaryDto>;
      final warehouses = responses[1] as List<WarehouseSummaryDto>;

      final filteredClubs = scope.isAdmin
          ? rawClubs
          : rawClubs.where((club) => scope.canViewClubId(club.id)).toList();

      final inventoryBuckets = await _loadInventoryEntries(scope, filteredClubs, warehouses);

      _clubsCache = filteredClubs;
      _personalInventoryCache = inventoryBuckets.personal;
      _clubInventoryCache = inventoryBuckets.club;
      _scope = scope;
      _isLoading = false;
      _hasError = false;
      _applySearch(_searchCtrl.text, notify: false);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  void _applySearch(String query, {bool notify = true}) {
    final scope = _scope;
    if (scope == null) return;
    final allowed = scope.isAdmin ? null : scope.accessibleClubIds;
    final personal = _localSearchService.searchInventory(
      _personalInventoryCache,
      query,
      allowedClubIds: allowed,
      includeAll: scope.isAdmin,
    );
    final club = _localSearchService.searchInventory(
      _clubInventoryCache,
      query,
      allowedClubIds: allowed,
      includeAll: scope.isAdmin,
    );
    _personalInventoryFiltered = personal;
    _clubInventoryFiltered = club;
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _applySearch(value));
  }

  Future<void> _refresh() => _bootstrap();

  void _clearSearch() {
    _searchCtrl.clear();
    _applySearch('');
  }

  Future<_InventoryBuckets> _loadInventoryEntries(
    UserAccessScope scope,
    List<ClubSummaryDto> clubs,
    List<WarehouseSummaryDto> warehouses,
  ) async {
    final personalEntries = <InventorySearchEntry>[];
    final clubEntries = <InventorySearchEntry>[];
    final seen = <String>{};
    final clubNames = <int, String>{
      for (final club in clubs) club.id: club.name,
    };

    final ids = scope.isAdmin
        ? clubNames.keys.toList()
        : scope.accessibleClubIds.where((id) => clubNames.containsKey(id)).toList();

    for (final id in ids) {
      try {
        final parts = await _inventoryRepository.search(query: '', clubId: id);
        final clubName = clubNames[id];
        for (final part in parts) {
          final key = '$id-${part.inventoryId}';
          if (seen.add(key)) {
            clubEntries.add(
              InventorySearchEntry(
                part: part,
                clubId: id,
                clubName: clubName,
                sourceLabel: clubName,
              ),
            );
          }
        }
      } catch (_) {
        // игнорируем сбои загрузки конкретного клуба
      }
    }

    final personalWarehouses = warehouses.where((w) {
      final type = w.warehouseType.toUpperCase();
      return type == 'PERSONAL' || w.personalAccess;
    }).toList();

    for (final warehouse in personalWarehouses) {
      try {
        final parts = await _inventoryRepository.getWarehouseInventory(
          warehouseId: warehouse.warehouseId,
          query: '',
        );
        for (final part in parts) {
          final key = 'personal-${warehouse.warehouseId}-${part.inventoryId}';
          if (seen.add(key)) {
            personalEntries.add(
              InventorySearchEntry(
                part: part,
                clubId: warehouse.clubId,
                clubName: warehouse.title,
                sourceLabel: warehouse.title.isNotEmpty ? warehouse.title : 'Личный ZIP-склад',
                isPersonal: true,
              ),
            );
          }
        }
      } catch (_) {
        // ignore personal warehouse errors
      }
    }

    return _InventoryBuckets(personal: personalEntries, club: clubEntries);
  }

  void _openInventory(InventorySearchEntry entry) {
    if (entry.isPersonal) {
      Navigator.pushNamed(context, Routes.personalWarehouse);
      return;
    }
    final clubId = entry.clubId;
    if (clubId == null) {
      _showMessage('Не удалось определить клуб для выбранной позиции');
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.clubWarehouse,
      arguments: ClubWarehouseArgs(
        warehouseId: clubId,
        clubId: clubId,
        clubName: entry.clubName,
        inventoryId: entry.part.inventoryId,
        searchQuery: entry.part.commonName ?? entry.part.catalogNumber,
      ),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Поиск',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Введите запрос по запчастям',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGray, size: 20),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: () => _applySearch(_searchCtrl.text),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) => BottomNavDirect.go(context, 1, i),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось выполнить поиск', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_personalInventoryFiltered.isEmpty && _clubInventoryFiltered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: const [
            SizedBox(height: 140),
            Center(
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: AppColors.darkGray),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (_personalInventoryFiltered.isNotEmpty) ...[
            _SectionHeader(
              title: 'Личный ZIP-склад',
              icon: Icons.inventory_2_outlined,
              count: _personalInventoryFiltered.length,
            ),
            const SizedBox(height: 8),
            ..._personalInventoryFiltered.map(
              (entry) => _InventorySearchTile(
                entry: entry,
                onTap: () => _openInventory(entry),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_clubInventoryFiltered.isNotEmpty) ...[
            _SectionHeader(
              title: 'Склад клуба',
              icon: Icons.storefront_outlined,
              count: _clubInventoryFiltered.length,
            ),
            const SizedBox(height: 8),
            ..._clubInventoryFiltered.map(
              (entry) => _InventorySearchTile(
                entry: entry,
                onTap: () => _openInventory(entry),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _InventoryBuckets {
  final List<InventorySearchEntry> personal;
  final List<InventorySearchEntry> club;

  const _InventoryBuckets({required this.personal, required this.club});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionHeader({required this.title, required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _InventorySearchTile extends StatelessWidget {
  final InventorySearchEntry entry;
  final VoidCallback onTap;

  const _InventorySearchTile({required this.entry, required this.onTap});

  String get _displayName {
    final part = entry.part;
    final candidates = [
      part.commonName,
      part.officialNameRu,
      part.officialNameEn,
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return part.catalogNumber;
  }

  @override
  Widget build(BuildContext context) {
    final part = entry.part;
    final info = <String>[];
    if (entry.sourceLabel != null && entry.sourceLabel!.isNotEmpty) {
      info.add(entry.sourceLabel!);
    } else if (entry.clubName != null && entry.clubName!.isNotEmpty) {
      info.add(entry.clubName!);
    }
    if (part.catalogNumber.isNotEmpty) {
      info.add('Каталожный номер: ${part.catalogNumber}');
    }
    if (part.location != null && part.location!.trim().isNotEmpty) {
      info.add('Локация: ${part.location!.trim()}');
    }
    if (part.quantity != null) {
      info.add('Количество: ${part.quantity}');
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFEDEDED), width: 1.2),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              info.isEmpty ? 'Детали отсутствуют' : info.join(' • '),
              style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
