import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/club_staff_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/repositories/inventory_repository.dart';
import '../../../../../core/routing/route_args.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import 'admin_club_create_screen.dart';

class AdminClubsScreen extends StatefulWidget {
  const AdminClubsScreen({super.key});

  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final ClubsRepository _clubsRepository = ClubsRepository();
  final ClubStaffRepository _staffRepository = ClubStaffRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_ClubEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final clubs = await _clubsRepository.getClubs();
      if (!mounted) return;

      setState(() {
        _entries = clubs
            .map(
              (club) => _ClubEntry(
                clubId: club.id,
                clubName: club.name,
                address: club.address,
                lanes: club.lanesCount,
                contactPhone: club.contactPhone,
                contactEmail: club.contactEmail,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e, s) {
      log('Failed to load clubs: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _entries = [];
      });
      showApiError(context, e);
    }
  }

  Future<void> _toggleClub(int index) async {
    final entry = _entries[index];
    final shouldOpen = !entry.isOpen;

    setState(() {
      entry.isOpen = shouldOpen;
      if (shouldOpen) {
        if (!entry.staffLoaded) {
          entry.isLoadingStaff = true;
          entry.staffError = false;
        }
        if (!entry.inventoryLoaded) {
          entry.isLoadingInventory = true;
          entry.inventoryError = false;
        }
      }
    });

    if (!shouldOpen) {
      return;
    }

    final futures = <Future<void>>[];
    if (!entry.staffLoaded) {
      futures.add(_loadEntryStaff(entry));
    }
    if (!entry.inventoryLoaded) {
      futures.add(_loadEntryInventory(entry));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _loadEntryStaff(_ClubEntry entry) async {
    try {
      final staff = await _loadStaff(entry.clubId);
      if (!mounted) return;
      final owner = staff.firstWhere(
        (m) => m.roleKey == 'OWNER',
        orElse: () => _StaffMemberInfo(roleKey: 'OWNER', displayRole: 'Владелец клуба/сети клубов', name: '', isActive: true),
      );
      setState(() {
        entry.staff = staff;
        if (owner.name.isNotEmpty) {
          entry.ownerName = owner.name;
        }
        entry.isLoadingStaff = false;
        entry.staffLoaded = true;
      });
    } catch (e, s) {
      log('Failed to load staff for club ${entry.clubId}: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        entry.isLoadingStaff = false;
        entry.staffError = true;
      });
    }
  }

  Future<void> _loadEntryInventory(_ClubEntry entry) async {
    if (entry.clubId == null) {
      if (mounted) {
        setState(() {
          entry.isLoadingInventory = false;
          entry.inventoryLoaded = true;
        });
      }
      return;
    }
    try {
      final inventory = await _inventoryRepository.search(query: '', clubId: entry.clubId);
      if (!mounted) return;
      setState(() {
        entry.inventoryCount = inventory.length;
        entry.equipmentSample = inventory
            .take(3)
            .map((e) => e.commonName ?? e.officialNameRu ?? e.catalogNumber)
            .where((name) => name != null && name!.isNotEmpty)
            .map((e) => e!)
            .join(', ');
        entry.isLoadingInventory = false;
        entry.inventoryLoaded = true;
      });
    } catch (e, s) {
      log('Failed to load inventory for club ${entry.clubId}: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        entry.isLoadingInventory = false;
        entry.inventoryError = true;
      });
    }
  }

  Future<List<_StaffMemberInfo>> _loadStaff(int clubId) async {
    final data = await _staffRepository.getClubStaff(clubId);
    return data.map((raw) {
      final item = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
      final rawRole = (item['role'] ?? item['roleKey'] ?? '').toString().toUpperCase();
      final roleKey = _normalizeRole(rawRole);
      final name = (item['fullName'] as String?)?.trim();
      final phone = (item['phone'] as String?)?.trim();
      final email = (item['email'] as String?)?.trim();
      final isActive = item['isActive'] is bool ? item['isActive'] as bool : true;
      return _StaffMemberInfo(
        roleKey: roleKey,
        displayRole: _mapRole(roleKey),
        name: (name != null && name.isNotEmpty) ? name : 'Без имени',
        phone: (phone != null && phone.isNotEmpty) ? phone : null,
        email: (email != null && email.isNotEmpty) ? email : null,
        isActive: isActive,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Боулинг клубы',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined, color: AppColors.primary),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminClubCreateScreen()),
              );
              if (created != null) {
                _loadClubs();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadClubs,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Не удалось загрузить список клубов', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadClubs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('Клубы не найдены'));
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: _loadClubs,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final entry = _entries[index];
          if (!entry.isOpen) {
            return _clubRow(entry, onTap: () => _toggleClub(index));
          }
          return _clubCard(entry, onCollapse: () => _toggleClub(index));
        },
      ),
    );
  }

  Widget _clubRow(_ClubEntry entry, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.clubName,
                style: const TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
          ],
        ),
      ),
    );
  }

  Widget _clubCard(_ClubEntry entry, {required VoidCallback onCollapse}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Text(
                    entry.clubName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _squareButton(Icons.keyboard_arrow_up_rounded, onTap: onCollapse),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Контакты клуба'),
          _infoTile(Icons.place_outlined, entry.address ?? '—'),
          const SizedBox(height: 10),
          _infoTile(Icons.phone, entry.contactPhone ?? '—'),
          if (entry.contactEmail != null && entry.contactEmail!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoTile(Icons.email_outlined, entry.contactEmail!),
          ],
          if (entry.ownerName != null && entry.ownerName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoTile(Icons.person, 'Владелец: ${entry.ownerName}'),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Параметры клуба'),
          _infoTile(Icons.confirmation_number, 'ID клуба: ${entry.clubId}'),
          const SizedBox(height: 10),
          _infoTile(Icons.view_stream_rounded, entry.lanes != null ? 'Количество дорожек: ${entry.lanes}' : 'Количество дорожек: —'),
          const SizedBox(height: 16),
          _sectionTitle('Сотрудники'),
          _buildStaffSection(entry),
          const SizedBox(height: 16),
          _sectionTitle('Склад клуба'),
          _buildInventorySection(entry),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.adminOrders),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('История заказов клуба', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.clubWarehouse,
                  arguments: ClubWarehouseArgs(
                    warehouseId: entry.clubId,
                    clubId: entry.clubId,
                    clubName: entry.clubName,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Перейти в склад клуба', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(_ClubEntry entry) {
    if (entry.isLoadingStaff) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (entry.staffError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('Не удалось загрузить список сотрудников')), 
      );
    }
    if (entry.staff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Сотрудники не назначены'),
      );
    }

    final groups = <String, List<_StaffMemberInfo>>{};
    for (final member in entry.staff) {
      groups.putIfAbsent(member.roleKey, () => []).add(member);
    }

    final order = ['OWNER', 'ADMIN', 'MANAGER', 'HEAD_MECHANIC', 'MECHANIC', 'STAFF'];
    final widgets = <Widget>[];
    var firstGroup = true;

    for (final role in order) {
      final members = groups.remove(role);
      if (members == null || members.isEmpty) continue;
      if (!firstGroup) {
        widgets.add(const SizedBox(height: 12));
      }
      firstGroup = false;
      widgets.add(_groupHeader(_mapRolePlural(role)));
      widgets.addAll(_buildStaffTiles(members));
    }

    if (groups.isNotEmpty) {
      if (!firstGroup) {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(_groupHeader('Другие сотрудники'));
      widgets.addAll(groups.values.expand(_buildStaffTiles));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _buildStaffTiles(List<_StaffMemberInfo> members) {
    final tiles = <Widget>[];
    for (var i = 0; i < members.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }
      tiles.add(_staffTile(members[i]));
    }
    return tiles;
  }

  Widget _staffTile(_StaffMemberInfo member) {
    final details = <String>[];
    if (member.phone != null) {
      details.add(member.phone!);
    }
    if (member.email != null) {
      details.add(member.email!);
    }
    if (!member.isActive) {
      details.add('Аккаунт отключён');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            member.displayRole,
            style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.join(' • '),
              style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventorySection(_ClubEntry entry) {
    if (entry.isLoadingInventory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (entry.inventoryError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Не удалось загрузить данные склада'),
      );
    }
    final count = entry.inventoryCount;
    if (count == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Информация о складе отсутствует'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(Icons.inventory_2_outlined, 'Позиции на складе: $count'),
        if (entry.equipmentSample != null && entry.equipmentSample!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _infoTile(Icons.build, 'Оборудование: ${entry.equipmentSample}'),
        ],
      ],
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _squareButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: AppColors.darkGray),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
    );
  }

  Widget _groupHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray),
    );
  }

  String _normalizeRole(String role) {
    switch (role) {
      case 'ADMINISTRATOR':
        return 'ADMIN';
      case 'HEAD_MANAGER':
      case 'CHIEF':
        return 'MANAGER';
      case 'HEAD_MECHANIC':
      case 'LEAD_MECHANIC':
        return 'HEAD_MECHANIC';
      case 'MECHANICS':
        return 'MECHANIC';
      case 'OWNERS':
        return 'OWNER';
      default:
        return role.isEmpty ? 'STAFF' : role;
    }
  }

  static String _mapRole(String roleKey) {
    switch (roleKey) {
      case 'OWNER':
        return 'Владелец клуба/сети клубов';
      case 'ADMIN':
        return 'Администратор';
      case 'MANAGER':
        return 'Менеджер';
      case 'HEAD_MECHANIC':
        return 'Старший механик';
      case 'MECHANIC':
        return 'Механик';
      default:
        return 'Сотрудник';
    }
  }

  static String _mapRolePlural(String roleKey) {
    switch (roleKey) {
      case 'OWNER':
        return 'Владельцы';
      case 'ADMIN':
        return 'Администраторы';
      case 'MANAGER':
        return 'Менеджеры';
      case 'HEAD_MECHANIC':
        return 'Старшие механики';
      case 'MECHANIC':
        return 'Механики';
      default:
        return 'Сотрудники';
    }
  }
}

class _ClubEntry {
  final int clubId;
  final String clubName;
  final String? address;
  final int? lanes;
  final String? contactPhone;
  final String? contactEmail;
  String? ownerName;
  String? equipmentSample;

  bool isOpen = false;
  bool isLoadingStaff = false;
  bool staffLoaded = false;
  bool staffError = false;
  List<_StaffMemberInfo> staff = [];

  bool isLoadingInventory = false;
  bool inventoryLoaded = false;
  bool inventoryError = false;
  int? inventoryCount;

  _ClubEntry({
    required this.clubId,
    required this.clubName,
    this.address,
    this.lanes,
    this.contactPhone,
    this.contactEmail,
  });
}

class _StaffMemberInfo {
  final String roleKey;
  final String displayRole;
  final String name;
  final String? phone;
  final String? email;
  final bool isActive;

  _StaffMemberInfo({
    required this.roleKey,
    required this.displayRole,
    required this.name,
    this.phone,
    this.email,
    required this.isActive,
  });
}
