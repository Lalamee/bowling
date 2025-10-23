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
  List<_MechanicEntry> _mechanics = [];
  int? _openIndex;

  @override
  void initState() {
    super.initState();
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final clubs = await _clubsRepository.getClubs();
      if (!mounted) return;

      final mechanics = <_MechanicEntry>[];
      for (final club in clubs) {
        final clubId = club.id;
        try {
          final staff = await _staffRepository.getClubStaff(clubId);
          for (final raw in staff) {
            final item = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
            final roleKey = (item['role']?.toString() ?? '').toUpperCase();
            if (roleKey != 'MECHANIC') continue;
            final name = (item['fullName'] as String?)?.trim();
            final phone = (item['phone'] as String?)?.trim();
            mechanics.add(
              _MechanicEntry(
                name: (name != null && name.isNotEmpty) ? name : 'Без имени',
                clubName: club.name ?? '—',
                clubAddress: club.address,
                phone: (phone != null && phone.isNotEmpty) ? phone : club.contactPhone,
              ),
            );
          }
        } catch (e, s) {
          log('Failed to load staff for club ${club.id}: $e', stackTrace: s);
        }
      }

      if (!mounted) return;
      setState(() {
        _mechanics = mechanics;
        _isLoading = false;
      });
    } catch (e, s) {
      log('Failed to load mechanics: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        showApiError(context, e);
      }
    }
  }

  void _toggle(int index) {
    setState(() {
      if (_openIndex == index) {
        _openIndex = null;
      } else {
        _openIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Механики', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        actions: [IconButton(onPressed: _loadMechanics, icon: const Icon(Icons.refresh_rounded), color: AppColors.primary)],
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
                        const Text('Не удалось загрузить список механиков', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadMechanics,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : _mechanics.isEmpty
                  ? const Center(child: Text('Механики не найдены'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _mechanics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final mechanic = _mechanics[i];
                        final isOpen = _openIndex == i;
                        return isOpen
                            ? _mechanicCard(mechanic, onCollapse: () => _toggle(i))
                            : _mechanicRow(mechanic, onTap: () => _toggle(i));
                      },
                    ),
    );
  }

  Widget _mechanicRow(_MechanicEntry mechanic, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 56,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(children: [
          Expanded(child: Text(mechanic.name, style: const TextStyle(fontSize: 16, color: AppColors.textDark))),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
        ]),
      ),
    );
  }

  Widget _mechanicCard(_MechanicEntry mechanic, {required VoidCallback onCollapse}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
              child: Text(mechanic.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ),
          ),
          const SizedBox(width: 8),
          _squareButton(Icons.keyboard_arrow_up_rounded, onTap: onCollapse),
        ]),
        const SizedBox(height: 12),
        _infoTile(Icons.house_outlined, mechanic.clubName),
        const SizedBox(height: 10),
        _infoTile(Icons.place_outlined, mechanic.clubAddress ?? '—'),
        const SizedBox(height: 10),
        _infoTile(Icons.phone, mechanic.phone ?? '—'),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, Routes.adminOrders),
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
}

class _MechanicEntry {
  final String name;
  final String clubName;
  final String? clubAddress;
  final String? phone;

  _MechanicEntry({required this.name, required this.clubName, this.clubAddress, this.phone});
}
