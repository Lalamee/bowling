import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/admin_mechanics_repository.dart';
import '../../../../../core/repositories/admin_users_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';

class AdminMechanicsScreen extends StatefulWidget {
  const AdminMechanicsScreen({super.key});

  @override
  State<AdminMechanicsScreen> createState() => _AdminMechanicsScreenState();
}

class _AdminMechanicsScreenState extends State<AdminMechanicsScreen> {
  final AdminMechanicsRepository _mechanicsRepository = AdminMechanicsRepository();
  final AdminUsersRepository _usersRepository = AdminUsersRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_PendingMechanic> _pending = [];
  List<_ClubMechanicsSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final overview = await _mechanicsRepository.getOverview();
      if (!mounted) return;

      final pending = overview.pending.map(_mapPending).where((m) => m.userId != null).toList();
      final sections = overview.clubs.map(_mapClub).toList();
      sections.sort((a, b) => (a.clubName ?? '').toLowerCase().compareTo((b.clubName ?? '').toLowerCase()));

      setState(() {
        _pending = pending;
        _sections = sections;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e, s) {
      log('Failed to load admin mechanics: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _pending = [];
        _sections = [];
      });
      showApiError(context, e);
    }
  }

  _PendingMechanic _mapPending(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    return _PendingMechanic(
      userId: _asInt(map['userId']),
      profileId: _asInt(map['profileId']),
      name: _asString(map['fullName']) ?? 'Без имени',
      phone: _asString(map['phone']),
      clubId: _asInt(map['requestedClubId']),
      clubName: _asString(map['requestedClubName']),
      clubAddress: _asString(map['requestedClubAddress']),
      createdAt: _asString(map['createdAt']),
      isActive: _asBool(map['isActive']),
      isVerified: _asBool(map['isVerified']),
      isDataVerified: _asBool(map['isDataVerified']),
    );
  }

  _ClubMechanicsSection _mapClub(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    final mechanicsRaw = map['mechanics'];
    final mechanics = mechanicsRaw is List ? mechanicsRaw.map(_mapMechanic).toList() : <_MechanicInfo>[];
    return _ClubMechanicsSection(
      clubId: _asInt(map['clubId']),
      clubName: _asString(map['clubName']) ?? 'Клуб',
      address: _asString(map['address']),
      contactPhone: _asString(map['contactPhone']),
      contactEmail: _asString(map['contactEmail']),
      mechanics: mechanics,
    );
  }

  _MechanicInfo _mapMechanic(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    return _MechanicInfo(
      userId: _asInt(map['userId']),
      profileId: _asInt(map['profileId']),
      name: _asString(map['fullName']) ?? 'Без имени',
      phone: _asString(map['phone']),
      isActive: _asBool(map['isActive']),
      isVerified: _asBool(map['isVerified']),
      isDataVerified: _asBool(map['isDataVerified']),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  void _toggleSection(int index) {
    setState(() {
      _sections[index].isOpen = !_sections[index].isOpen;
    });
  }

  Future<void> _approvePending(int index) async {
    final mechanic = _pending[index];
    if (mechanic.userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение механика'),
        content: Text('Подтвердить регистрацию механика "${mechanic.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Подтвердить')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      mechanic.isProcessing = true;
    });

    try {
      final success = await _usersRepository.verify('${mechanic.userId}');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Механик подтверждён')),
        );
        await _loadData();
      } else {
        throw Exception('Не удалось подтвердить механика');
      }
    } catch (e, s) {
      log('Failed to verify mechanic ${mechanic.userId}: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        mechanic.isProcessing = false;
      });
      showApiError(context, e);
    }
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
          'Механики',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
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
              const Text('Не удалось загрузить список механиков', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pending.isEmpty && _sections.isEmpty) {
      return const Center(child: Text('Механики не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (_pending.isNotEmpty) ...[
            _buildPendingSection(),
            const SizedBox(height: 16),
          ],
          if (_sections.isEmpty)
            const Center(child: Text('Клубы с механиками не найдены'))
          else
            for (var i = 0; i < _sections.length; i++) ...[
              _buildSectionCard(_sections[i], i),
              if (i < _sections.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ожидают подтверждения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _pending.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildPendingTile(_pending[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingTile(_PendingMechanic mechanic, int index) {
    final info = <String>[];
    if (mechanic.phone != null) {
      info.add(mechanic.phone!);
    }
    if (mechanic.clubName != null) {
      info.add('Клуб: ${mechanic.clubName}');
    }
    if (mechanic.createdAt != null) {
      info.add('Заявка от ${mechanic.createdAt}');
    }

    final status = <String>[];
    if (mechanic.isActive == false) {
      status.add('Аккаунт отключён');
    }
    if (mechanic.isVerified != true || mechanic.isDataVerified != true) {
      status.add('Требует подтверждения');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mechanic.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(info.join(' • '), style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
          ],
          if (status.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(status.join(' • '), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: (mechanic.userId == null || mechanic.isProcessing) ? null : () => _approvePending(index),
              icon: mechanic.isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(mechanic.isProcessing ? 'Обработка…' : 'Подтвердить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_ClubMechanicsSection section, int index) {
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
                      section.clubName ?? 'Клуб',
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

  Widget _buildSectionContent(_ClubMechanicsSection section) {
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
    children.add(_sectionTitle('Механики клуба'));

    if (section.mechanics.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Механики не назначены')),
      ));
    } else {
      children.addAll(_buildMechanicTiles(section.mechanics));
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

  List<Widget> _buildMechanicTiles(List<_MechanicInfo> mechanics) {
    final tiles = <Widget>[];
    for (var i = 0; i < mechanics.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }
      tiles.add(_mechanicTile(mechanics[i]));
    }
    return tiles;
  }

  Widget _mechanicTile(_MechanicInfo mechanic) {
    final details = <String>[];
    if (mechanic.phone != null) {
      details.add(mechanic.phone!);
    }

    final statuses = <String>[];
    if (mechanic.isActive == false) {
      statuses.add('Аккаунт отключён');
    }
    if (mechanic.isVerified != true) {
      statuses.add('Не подтверждён');
    } else if (mechanic.isDataVerified != true) {
      statuses.add('Данные не подтверждены');
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
            mechanic.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.join(' • '),
              style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
            ),
          ],
          if (statuses.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              statuses.join(' • '),
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
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
}

class _PendingMechanic {
  final int? userId;
  final int? profileId;
  final String name;
  final String? phone;
  final int? clubId;
  final String? clubName;
  final String? clubAddress;
  final String? createdAt;
  final bool? isActive;
  final bool? isVerified;
  final bool? isDataVerified;
  bool isProcessing = false;

  _PendingMechanic({
    required this.userId,
    required this.profileId,
    required this.name,
    this.phone,
    this.clubId,
    this.clubName,
    this.clubAddress,
    this.createdAt,
    this.isActive,
    this.isVerified,
    this.isDataVerified,
  });
}

class _ClubMechanicsSection {
  final int? clubId;
  final String? clubName;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final List<_MechanicInfo> mechanics;
  bool isOpen = false;

  _ClubMechanicsSection({
    required this.clubId,
    required this.clubName,
    required this.address,
    required this.contactPhone,
    required this.contactEmail,
    required this.mechanics,
  });
}

class _MechanicInfo {
  final int? userId;
  final int? profileId;
  final String name;
  final String? phone;
  final bool? isActive;
  final bool? isVerified;
  final bool? isDataVerified;

  _MechanicInfo({
    required this.userId,
    required this.profileId,
    required this.name,
    this.phone,
    this.isActive,
    this.isVerified,
    this.isDataVerified,
  });
}
