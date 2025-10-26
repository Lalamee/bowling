import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/club_staff_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/utils/net_ui.dart';

class AdminClubsScreen extends StatefulWidget {
  const AdminClubsScreen({super.key});
  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final ClubsRepository _clubsRepository = ClubsRepository();
  final ClubStaffRepository _staffRepository = ClubStaffRepository();

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
            .map((club) => _ClubEntry(clubId: club.id, clubName: club.name)
              ..address = club.address
              ..lanes = club.lanesCount
              ..contactPhone = club.contactPhone
              ..contactEmail = club.contactEmail)
            .toList();
        _isLoading = false;
      });
    } catch (e, s) {
      log('Failed to load clubs: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        showApiError(context, e);
      }
    }
  }

  Future<void> _toggleClub(int index) async {
    final entry = _entries[index];
    if (entry.isOpen) {
      setState(() => entry.isOpen = false);
      return;
    }

    setState(() {
      for (var i = 0; i < _entries.length; i++) {
        if (i == index) {
          _entries[i].isOpen = true;
          if (!_entries[i].staffLoaded) {
            _entries[i].isLoadingStaff = true;
          }
        } else {
          _entries[i].isOpen = false;
        }
      }
    });

    if (!entry.staffLoaded) {
      try {
        final staff = await _loadStaff(entry.clubId);
        if (!mounted) return;
        setState(() {
          entry.staff = staff;
          entry.isLoadingStaff = false;
          entry.staffLoaded = true;
        });
      } catch (e, s) {
        log('Failed to load staff for club ${entry.clubId}: $e', stackTrace: s);
        if (mounted) {
          setState(() {
            entry.isLoadingStaff = false;
          });
          showApiError(context, e);
        }
      }
    }
  }

  Future<List<_StaffMemberInfo>> _loadStaff(int? clubId) async {
    if (clubId == null) return [];
    final data = await _staffRepository.getClubStaff(clubId);
    return data.map((raw) {
      final item = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
      final roleKey = (item['role']?.toString() ?? '').toUpperCase();
      final name = (item['fullName'] as String?)?.trim();
      final phone = (item['phone'] as String?)?.trim();
      return _StaffMemberInfo(
        roleKey: roleKey,
        displayRole: _mapRole(roleKey),
        name: (name != null && name.isNotEmpty) ? name : 'Без имени',
        phone: (phone != null && phone.isNotEmpty) ? phone : null,
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
        title: const Text('Боулинг клубы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadClubs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final entry = _entries[i];
                    if (!entry.isOpen) {
                      return _clubRow(entry, onTap: () => _toggleClub(i));
                    }
                    return _clubCard(entry, onCollapse: () => _toggleClub(i), onGoHistory: () => Navigator.pushNamed(context, Routes.adminOrders));
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
        child: Row(children: [
          Expanded(child: Text(entry.clubName, style: const TextStyle(fontSize: 16, color: AppColors.textDark))),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
        ]),
      ),
    );
  }

  Widget _clubCard(_ClubEntry entry, {required VoidCallback onCollapse, required VoidCallback onGoHistory}) {
    final owner = entry.staff.firstWhere((s) => s.roleKey == 'OWNER', orElse: () => _StaffMemberInfo(roleKey: 'OWNER', displayRole: 'Владелец клуба', name: 'Не назначен'));
    final mechanic = entry.staff.firstWhere((s) => s.roleKey == 'MECHANIC', orElse: () => _StaffMemberInfo(roleKey: 'MECHANIC', displayRole: 'Механик', name: 'Механики не назначены'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
              child: Text(entry.clubName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
          ),
          const SizedBox(width: 8),
          _squareButton(Icons.keyboard_arrow_up_rounded, onTap: onCollapse),
        ]),
        const SizedBox(height: 12),
        if (entry.isLoadingStaff)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          )
        else ...[
          _infoTile(Icons.person, owner.name ?? 'Владелец не указан'),
          const SizedBox(height: 10),
          _infoTile(Icons.phone, owner.phone ?? entry.contactPhone ?? '—'),
          const SizedBox(height: 10),
          _infoTile(Icons.assignment_ind_outlined, 'ИНН: —'),
          const SizedBox(height: 10),
          _infoTile(Icons.house_outlined, entry.clubName),
          const SizedBox(height: 10),
          _infoTile(Icons.place_outlined, entry.address ?? '—'),
          const SizedBox(height: 10),
          _infoTile(Icons.engineering_outlined, mechanic.name ?? 'Механики не назначены'),
          if (entry.contactEmail != null && entry.contactEmail!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoTile(Icons.email_outlined, entry.contactEmail!),
          ],
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onGoHistory,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Перейти в историю заказов клуба', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
      child: Row(children: [
        Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ]),
    );
  }

  Widget _squareButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(icon, color: AppColors.darkGray)),
    );
  }

  static String _mapRole(String roleKey) {
    switch (roleKey) {
      case 'OWNER':
        return 'Владелец клуба';
      case 'ADMIN':
      case 'ADMINISTRATOR':
        return 'Администратор';
      case 'HEAD_MECHANIC':
      case 'MANAGER':
        return 'Менеджер';
      case 'MECHANIC':
        return 'Механик';
      default:
        return roleKey.isEmpty ? 'Сотрудник' : roleKey;
    }
  }
}

class _ClubEntry {
  final int? clubId;
  final String clubName;
  String? address;
  int? lanes;
  String? contactPhone;
  String? contactEmail;
  bool isOpen = false;
  bool isLoadingStaff = false;
  bool staffLoaded = false;
  List<_StaffMemberInfo> staff = [];

  _ClubEntry({required this.clubId, required this.clubName});
}

class _StaffMemberInfo {
  final String roleKey;
  final String displayRole;
  final String? name;
  final String? phone;

  _StaffMemberInfo({required this.roleKey, required this.displayRole, required this.name, this.phone});
}
