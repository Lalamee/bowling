import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/order_status.dart';
import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/club_summary_dto.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../services/local_search_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _maintenanceRepository = MaintenanceRepository();
  final _clubsRepository = ClubsRepository();
  final _userRepository = UserRepository();
  final _inventoryRepository = InventoryRepository();
  final _localSearchService = const LocalSearchService();

  final _searchCtrl = TextEditingController();
  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

  Timer? _debounce;
  bool _isLoading = true;
  bool _hasError = false;
  UserAccessScope? _scope;

  List<MaintenanceRequestResponseDto> _ordersCache = const <MaintenanceRequestResponseDto>[];
  List<ClubSummaryDto> _clubsCache = const <ClubSummaryDto>[];
  List<MaintenanceRequestResponseDto> _ordersFiltered = const <MaintenanceRequestResponseDto>[];
  List<ClubSummaryDto> _clubsFiltered = const <ClubSummaryDto>[];
  List<InventorySearchEntry> _inventoryCache = const <InventorySearchEntry>[];
  List<ProfileSearchEntry> _profilesCache = const <ProfileSearchEntry>[];
  List<InventorySearchEntry> _inventoryFiltered = const <InventorySearchEntry>[];
  List<ProfileSearchEntry> _profilesFiltered = const <ProfileSearchEntry>[];

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
        _maintenanceRepository.getAllRequests(),
        _clubsRepository.getClubs(),
      ]);
      if (!mounted) return;
      final rawOrders = responses[0] as List<MaintenanceRequestResponseDto>;
      final rawClubs = responses[1] as List<ClubSummaryDto>;

      final filteredOrders = scope.isAdmin
          ? rawOrders
          : rawOrders.where(scope.canViewOrder).toList();
      final filteredClubs = scope.isAdmin
          ? rawClubs
          : rawClubs.where((club) => scope.canViewClubId(club.id)).toList();

      final inventoryEntries = await _loadInventoryEntries(scope, filteredClubs);
      final profileEntries = _buildProfileEntries(me, scope);

      _ordersCache = filteredOrders;
      _clubsCache = filteredClubs;
      _inventoryCache = inventoryEntries;
      _profilesCache = profileEntries;
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
    final orders = _localSearchService.searchOrders(
      _ordersCache,
      query,
      allowedClubIds: allowed,
      includeAll: scope.isAdmin,
    );
    final clubs = _localSearchService.searchClubs(
      _clubsCache,
      query,
      allowedClubIds: allowed,
      includeAll: scope.isAdmin,
    );
    final inventory = _localSearchService.searchInventory(
      _inventoryCache,
      query,
      allowedClubIds: allowed,
      includeAll: scope.isAdmin,
    );
    final profiles = _localSearchService.searchProfiles(
      _profilesCache,
      query,
    );
    _ordersFiltered = orders;
    _clubsFiltered = clubs;
    _inventoryFiltered = inventory;
    _profilesFiltered = profiles;
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

  Future<List<InventorySearchEntry>> _loadInventoryEntries(
    UserAccessScope scope,
    List<ClubSummaryDto> clubs,
  ) async {
    final entries = <InventorySearchEntry>[];
    final seen = <String>{};
    final clubNames = <int, String>{
      for (final club in clubs) club.id: club.name,
    };

    final ids = scope.isAdmin
        ? clubNames.keys.toList()
        : scope.accessibleClubIds.where((id) => clubNames.containsKey(id)).toList();

    if (ids.isEmpty) {
      return entries;
    }

    for (final id in ids) {
      try {
        final parts = await _inventoryRepository.search(query: '', clubId: id);
        final clubName = clubNames[id];
        for (final part in parts) {
          final key = '$id-${part.inventoryId}';
          if (seen.add(key)) {
            entries.add(InventorySearchEntry(part: part, clubId: id, clubName: clubName));
          }
        }
      } catch (_) {
        // игнорируем сбои загрузки конкретного клуба
      }
    }

    return entries;
  }

  List<ProfileSearchEntry> _buildProfileEntries(Map<String, dynamic> me, UserAccessScope scope) {
    String? asString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final displayName =
        asString(me['fullName']) ?? asString(me['name']) ?? asString(me['phone']) ?? 'Профиль';
    final phone = asString(me['phone']);
    final email = asString(me['email']);
    final route = _profileRouteForRole(scope.role);
    if (route == null) {
      return const [];
    }

    return [
      ProfileSearchEntry(
        displayName: displayName,
        phone: phone,
        email: email,
        route: route,
        roleLabel: _roleLabelForRole(scope.role),
      ),
    ];
  }

  String? _profileRouteForRole(String role) {
    switch (role) {
      case 'admin':
        return Routes.profileAdmin;
      case 'manager':
        return Routes.profileManager;
      case 'owner':
        return Routes.profileOwner;
      case 'mechanic':
        return Routes.profileMechanic;
      default:
        return null;
    }
  }

  String _roleLabelForRole(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'manager':
        return 'Менеджер';
      case 'owner':
        return 'Владелец';
      case 'mechanic':
        return 'Механик';
      default:
        return role;
    }
  }

  void _openOrder(MaintenanceRequestResponseDto order) {
    Navigator.pushNamed(
      context,
      Routes.orderSummary,
      arguments: OrderSummaryArgs(order: order, orderNumber: 'Заявка №${order.requestId}'),
    );
  }

  void _openClub(ClubSummaryDto club) {
    Navigator.pushNamed(context, Routes.club, arguments: club.id);
  }

  void _openInventory(InventorySearchEntry entry) {
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

  void _openProfile(ProfileSearchEntry entry) {
    Navigator.pushNamed(context, entry.route, arguments: entry.arguments);
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
                        hintText: 'Введите запрос по заявкам или клубам',
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

    if (_ordersFiltered.isEmpty &&
        _clubsFiltered.isEmpty &&
        _inventoryFiltered.isEmpty &&
        _profilesFiltered.isEmpty) {
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
          if (_ordersFiltered.isNotEmpty) ...[
            _SectionHeader(title: 'Заявки', icon: Icons.assignment_outlined, count: _ordersFiltered.length),
            const SizedBox(height: 8),
            ..._ordersFiltered.map(
              (order) => _OrderSearchTile(
                order: order,
                formatter: _dateFormatter,
                onTap: () => _openOrder(order),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_clubsFiltered.isNotEmpty) ...[
            _SectionHeader(title: 'Клубы', icon: Icons.storefront_outlined, count: _clubsFiltered.length),
            const SizedBox(height: 8),
            ..._clubsFiltered.map(
              (club) => _ClubSearchTile(
                club: club,
                onTap: () => _openClub(club),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_inventoryFiltered.isNotEmpty) ...[
            _SectionHeader(title: 'Склад', icon: Icons.inventory_2_outlined, count: _inventoryFiltered.length),
            const SizedBox(height: 8),
            ..._inventoryFiltered.map(
              (entry) => _InventorySearchTile(
                entry: entry,
                onTap: () => _openInventory(entry),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_profilesFiltered.isNotEmpty) ...[
            _SectionHeader(title: 'Пользователи', icon: Icons.person_outline, count: _profilesFiltered.length),
            const SizedBox(height: 8),
            ..._profilesFiltered.map(
              (entry) => _ProfileSearchTile(
                entry: entry,
                onTap: () => _openProfile(entry),
              ),
            ),
          ],
        ],
      ),
    );
  }
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

class _OrderSearchTile extends StatelessWidget {
  final MaintenanceRequestResponseDto order;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _OrderSearchTile({required this.order, required this.formatter, required this.onTap});

  DateTime? get _lastUpdate {
    DateTime? latest;
    void consider(DateTime? value) {
      if (value == null) return;
      if (latest == null || value.isAfter(latest!)) {
        latest = value;
      }
    }

    consider(order.managerDecisionDate);
    consider(order.completionDate);
    consider(order.requestDate);
    for (final part in order.requestedParts) {
      consider(part.deliveryDate);
      consider(part.issueDate);
      consider(part.orderDate);
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      subtitle.add(order.clubName!);
    }
    subtitle.add(describeOrderStatus(order.status));
    final updated = _lastUpdate;
    if (updated != null) {
      subtitle.add(formatter.format(updated));
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Заявка №${order.requestId}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    describeOrderStatus(order.status),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle.join(' • '),
              style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
            ),
            if (order.managerNotes != null && order.managerNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                order.managerNotes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClubSearchTile extends StatelessWidget {
  final ClubSummaryDto club;

  final VoidCallback onTap;

  const _ClubSearchTile({required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    if (club.address != null && club.address!.isNotEmpty) {
      details.add(club.address!);
    }
    if (club.contactPhone != null && club.contactPhone!.isNotEmpty) {
      details.add(club.contactPhone!);
    }
    if (club.contactEmail != null && club.contactEmail!.isNotEmpty) {
      details.add(club.contactEmail!);
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
              club.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              details.isEmpty ? 'Контакты не указаны' : details.join(' • '),
              style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
            ),
          ],
        ),
      ),
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
    if (entry.clubName != null && entry.clubName!.isNotEmpty) {
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

class _ProfileSearchTile extends StatelessWidget {
  final ProfileSearchEntry entry;
  final VoidCallback onTap;

  const _ProfileSearchTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    if (entry.roleLabel != null && entry.roleLabel!.isNotEmpty) {
      details.add(entry.roleLabel!);
    }
    if (entry.phone != null && entry.phone!.isNotEmpty) {
      details.add(entry.phone!);
    }
    if (entry.email != null && entry.email!.isNotEmpty) {
      details.add(entry.email!);
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
              entry.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              details.isEmpty ? 'Контакты отсутствуют' : details.join(' • '),
              style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
