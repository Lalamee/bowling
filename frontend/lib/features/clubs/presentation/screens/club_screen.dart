import 'package:flutter/material.dart';

import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../shared/widgets/layout/section_list.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import 'club_warehouse_screen.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({Key? key}) : super(key: key);

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  final _userRepository = UserRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_ClubInfo> _clubs = const [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      if (!mounted) return;
      final clubs = _extractClubs(me);
      setState(() {
        _clubs = clubs;
        _selectedIndex = clubs.isNotEmpty ? 0 : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  List<_ClubInfo> _extractClubs(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final result = <_ClubInfo>[];
    final seen = <String>{};

    void addClub({required String name, String? address, String? lanes, String? equipment}) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      if (seen.contains(trimmed.toLowerCase())) return;
      seen.add(trimmed.toLowerCase());
      result.add(_ClubInfo(name: trimmed, address: address, lanes: lanes, equipment: equipment));
    }

    final ownerProfile = data['ownerProfile'];
    if (ownerProfile is Map) {
      final map = Map<String, dynamic>.from(ownerProfile);
      final detailed = map['clubsDetailed'];
      if (detailed is Iterable) {
        for (final entry in detailed) {
          if (entry is Map) {
            final club = Map<String, dynamic>.from(entry);
            addClub(
              name: (club['name'] ?? '') as String,
              address: club['address']?.toString(),
              lanes: club['lanes']?.toString(),
              equipment: club['equipment']?.toString(),
            );
          }
        }
      }
      final clubName = map['clubName']?.toString();
      if (clubName != null) {
        addClub(
          name: clubName,
          address: map['address']?.toString() ?? map['legalAddress']?.toString(),
          lanes: map['lanes']?.toString(),
          equipment: map['equipment']?.toString(),
        );
      }
    }

    final managerProfile = data['managerProfile'];
    if (managerProfile is Map) {
      final map = Map<String, dynamic>.from(managerProfile);
      final clubs = map['clubs'];
      if (clubs is Iterable) {
        for (final raw in clubs) {
          if (raw == null) continue;
          addClub(name: raw.toString(), address: map['address']?.toString());
        }
      }
      final clubName = map['clubName']?.toString();
      if (clubName != null) {
        addClub(name: clubName, address: map['address']?.toString());
      }
    }

    final mechanicProfile = data['mechanicProfile'];
    if (mechanicProfile is Map) {
      final map = Map<String, dynamic>.from(mechanicProfile);
      final clubs = map['clubs'];
      if (clubs is Iterable) {
        for (final raw in clubs) {
          if (raw == null) continue;
          addClub(name: raw.toString(), address: map['address']?.toString());
        }
      }
      final clubName = map['clubName']?.toString();
      if (clubName != null) {
        addClub(name: clubName, address: map['address']?.toString());
      }
    }

    final fallbackName = data['clubName']?.toString();
    if (fallbackName != null) {
      addClub(name: fallbackName, address: data['address']?.toString());
    }

    return result;
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _openWarehouse() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubWarehouseScreen()));
  }

  void _openCreateRequest() {
    Navigator.pushNamed(context, Routes.createMaintenanceRequest);
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
            const Text('Не удалось загрузить информацию о клубах', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadClubs,
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
    if (_clubs.isEmpty) {
      return const Center(
        child: Text(
          'Для вашего аккаунта нет привязанных клубов',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    final items = _clubs.map((club) => club.name).toList();
    final selectedClub = _selectedIndex != null ? _clubs[_selectedIndex!] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        CommonUI.card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Клуб',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadClubs,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionList(
          items: items,
          selected: _selectedIndex ?? -1,
          onSelect: _onSelect,
        ),
        const SizedBox(height: 16),
        if (selectedClub != null) _ClubDetailsCard(club: selectedClub),
        const SizedBox(height: 20),
        CustomButton(text: 'Добавить деталь в заказ', onPressed: _openCreateRequest),
        const SizedBox(height: 12),
        CustomButton(text: 'Открыть склад', isOutlined: true, onPressed: _openWarehouse),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) => BottomNavDirect.go(context, 2, i),
      ),
    );
  }
}

class _ClubDetailsCard extends StatelessWidget {
  final _ClubInfo club;

  const _ClubDetailsCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return CommonUI.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on_rounded, label: 'Адрес', value: club.address ?? 'Не указан'),
          if (club.lanes != null && club.lanes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.format_list_numbered, label: 'Дорожек', value: club.lanes!),
          ],
          if (club.equipment != null && club.equipment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.memory_rounded, label: 'Оборудование', value: club.equipment!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubInfo {
  final String name;
  final String? address;
  final String? lanes;
  final String? equipment;

  const _ClubInfo({
    required this.name,
    this.address,
    this.lanes,
    this.equipment,
  });
}
