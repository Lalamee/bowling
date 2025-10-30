import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/club_staff_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';

class AdminMechanicsScreen extends StatefulWidget {
  const AdminMechanicsScreen({super.key});

  @override
  State<AdminMechanicsScreen> createState() => _AdminMechanicsScreenState();
}

class _AdminMechanicsScreenState extends State<AdminMechanicsScreen> {
  final ClubsRepository _clubsRepository = ClubsRepository();
  final ClubStaffRepository _staffRepository = ClubStaffRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_ClubStaffSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final clubs = await _clubsRepository.getClubs();
      if (!mounted) return;

      setState(() {
        _sections = clubs
            .map(
              (club) => _ClubStaffSection(
                clubId: club.id,
                clubName: club.name,
                address: club.address,
                contactPhone: club.contactPhone,
                contactEmail: club.contactEmail,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e, s) {
      log('Failed to load admin clubs: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _sections = [];
      });
      showApiError(context, e);
    }
  }

  Future<void> _toggleSection(int index) async {
    final section = _sections[index];
    setState(() {
      section.isOpen = !section.isOpen;
      if (section.isOpen && !section.staffLoaded) {
        section.isLoading = true;
        section.hasError = false;
      }
    });

    if (!section.isOpen || section.staffLoaded) {
      return;
    }

    try {
      final staff = await _staffRepository.getClubStaff(section.clubId);
      if (!mounted) return;

      setState(() {
        section.staff = staff.map(_mapStaffMember).toList();
        section.isLoading = false;
        section.staffLoaded = true;
      });
    } catch (e, s) {
      log('Failed to load staff for club ${section.clubId}: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        section.isLoading = false;
        section.hasError = true;
      });
      showApiError(context, e);
    }
  }

  _StaffMember _mapStaffMember(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    final originalRole = (map['role'] ?? map['roleKey'] ?? '').toString().toUpperCase();
    final normalizedRole = _normalizeRole(originalRole);
    final name = (map['fullName'] as String?)?.trim();
    final phone = (map['phone'] as String?)?.trim();
    final email = (map['email'] as String?)?.trim();
    final isActive = map['isActive'] is bool ? map['isActive'] as bool : true;

    return _StaffMember(
      roleKey: normalizedRole,
      displayRole: _mapRoleToLabel(normalizedRole),
      name: (name != null && name.isNotEmpty) ? name : 'Без имени',
      phone: (phone != null && phone.isNotEmpty) ? phone : null,
      email: (email != null && email.isNotEmpty) ? email : null,
      isActive: isActive,
    );
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
          'Сотрудники клубов',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _loadSections,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
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
              const Text('Не удалось загрузить список сотрудников', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadSections,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sections.isEmpty) {
      return const Center(child: Text('Клубы не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _loadSections,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildSectionCard(_sections[index], index),
      ),
    );
  }

  Widget _buildSectionCard(_ClubStaffSection section, int index) {
    final borderColor = section.isOpen ? AppColors.primary : AppColors.lightGray;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(index),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.clubName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                  Icon(
                    section.isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkGray,
                  ),
                ],
              ),
            ),
          ),
          if (section.isOpen) const Divider(height: 1),
          if (section.isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildSectionContent(section),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(_ClubStaffSection section) {
    final children = <Widget>[
      _sectionTitle('Контактная информация'),
      _infoTile(Icons.place_outlined, section.address ?? '—'),
    ];

    if (section.contactPhone != null && section.contactPhone!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(_infoTile(Icons.phone, section.contactPhone!.trim()));
    }
    if (section.contactEmail != null && section.contactEmail!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(_infoTile(Icons.email_outlined, section.contactEmail!.trim()));
    }

    children.add(const SizedBox(height: 16));
    children.add(_sectionTitle('Сотрудники клуба'));

    if (section.isLoading) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (section.hasError) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Не удалось загрузить сотрудников')), 
      ));
    } else if (section.staff.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Сотрудники не назначены')), 
      ));
    } else {
      children.addAll(_buildGroupedStaff(section.staff));
    }

    children.add(const SizedBox(height: 16));
    children.add(
      SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, Routes.adminOrders),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.history_rounded),
          label: const Text('История заказов клуба'),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _buildGroupedStaff(List<_StaffMember> staff) {
    final groups = <String, List<_StaffMember>>{};
    for (final member in staff) {
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
      widgets.add(_groupHeader(_mapRoleToPlural(role)));
      widgets.addAll(_buildStaffTiles(members));
    }

    if (groups.isNotEmpty) {
      if (!firstGroup) {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(_groupHeader('Другие сотрудники'));
      widgets.addAll(groups.values.expand(_buildStaffTiles));
    }

    return widgets;
  }

  List<Widget> _buildStaffTiles(List<_StaffMember> members) {
    final tiles = <Widget>[];
    for (var i = 0; i < members.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }
      tiles.add(_staffTile(members[i]));
    }
    return tiles;
  }

  Widget _staffTile(_StaffMember member) {
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
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

  String _mapRoleToLabel(String role) {
    switch (role) {
      case 'OWNER':
        return 'Владелец клуба';
      case 'ADMIN':
        return 'Администратор клуба';
      case 'MANAGER':
        return 'Менеджер клуба';
      case 'HEAD_MECHANIC':
        return 'Старший механик';
      case 'MECHANIC':
        return 'Механик';
      default:
        return 'Сотрудник клуба';
    }
  }

  String _mapRoleToPlural(String role) {
    switch (role) {
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

class _ClubStaffSection {
  final int clubId;
  final String clubName;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  bool isOpen = false;
  bool isLoading = false;
  bool staffLoaded = false;
  bool hasError = false;
  List<_StaffMember> staff = [];

  _ClubStaffSection({
    required this.clubId,
    required this.clubName,
    this.address,
    this.contactPhone,
    this.contactEmail,
  });
}

class _StaffMember {
  final String roleKey;
  final String displayRole;
  final String name;
  final String? phone;
  final String? email;
  final bool isActive;

  _StaffMember({
    required this.roleKey,
    required this.displayRole,
    required this.name,
    this.phone,
    this.email,
    required this.isActive,
  });
}
