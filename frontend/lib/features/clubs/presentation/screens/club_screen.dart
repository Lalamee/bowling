import 'package:flutter/material.dart';

import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../shared/widgets/layout/section_list.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../orders/presentation/screens/add_parts_to_order_screen.dart';
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
  List<UserClub> _clubs = const [];
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
      final clubs = resolveUserClubs(me);
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

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _openWarehouse() {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubWarehouseScreen(
          clubId: selected.id,
          clubName: selected.name,
        ),
      ),
    );
  }

  Future<void> _openAddPartFlow() async {
    final selected = _selectedIndex != null ? _clubs[_selectedIndex!] : null;
    if (selected == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final selectedOrder = await showModalBottomSheet<MaintenanceRequestResponseDto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderSelectionSheet(clubId: selected.id, clubName: selected.name),
    );

    if (!mounted || selectedOrder == null) return;

    final result = await Navigator.push<MaintenanceRequestResponseDto>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPartsToOrderScreen(
          order: selectedOrder,
          clubId: selected.id,
          clubName: selected.name,
        ),
      ),
    );

    if (result != null && mounted) {
      showSnack(context, 'Детали добавлены в заявку №${result.requestId}');
    }
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: _logout,
              child: const Text('Выйти из аккаунта'),
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
        CustomButton(text: 'Добавить деталь в заказ', onPressed: _openAddPartFlow),
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
  final UserClub club;

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
          if (club.phone != null && club.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone, label: 'Телефон', value: club.phone!),
          ],
          if (club.email != null && club.email!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: club.email!),
          ],
        ],
      ),
    );
  }
}

class _OrderSelectionSheet extends StatefulWidget {
  final int clubId;
  final String clubName;

  const _OrderSelectionSheet({required this.clubId, required this.clubName});

  @override
  State<_OrderSelectionSheet> createState() => _OrderSelectionSheetState();
}

class _OrderSelectionSheetState extends State<_OrderSelectionSheet> {
  final _repository = MaintenanceRepository();
  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _statusName(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'Новая заявка';
      case 'APPROVED':
        return 'Одобрено';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'DONE':
        return 'Выполнено';
      case 'COMPLETED':
        return 'Завершено';
      case 'CLOSED':
        return 'Закрыто';
      case 'UNREPAIRABLE':
        return 'Неремонтопригодно';
      case 'REJECTED':
        return 'Отклонено';
      default:
        return status;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final orders = await _repository.getRequestsByClub(widget.clubId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Выберите заказ для клуба "${widget.clubName}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
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
            const Icon(Icons.cloud_off, size: 48, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить заказы', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
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
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'Для выбранного клуба пока нет заявок',
          style: TextStyle(color: AppColors.darkGray),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            title: Text(
              'Заявка №${order.requestId}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.laneNumber != null)
                  Text('Дорожка ${order.laneNumber}', style: const TextStyle(color: AppColors.darkGray)),
                if (order.status != null && order.status!.isNotEmpty)
                  Text('Статус: ${_statusName(order.status!)}', style: const TextStyle(color: AppColors.darkGray)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkGray),
            onTap: () => Navigator.pop(context, order),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _orders.length,
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

