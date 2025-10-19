import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../core/utils/net_ui.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _repo = MaintenanceRepository();
  final clubs = const ['Все клубы', 'Боулинг клуб "Адреналин"', 'Боулинг клуб "Кегли"', 'Боулинг клуб "Шары"'];
  int selectedClub = 0;
  int? expandedOrder;
  bool isLoading = true;
  List<MaintenanceRequestResponseDto> requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);
    try {
      final data = await _repo.getAllRequests();
      if (mounted) {
        setState(() {
          requests = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showApiError(context, e);
      }
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, Routes.profileAdmin);
            }
          },
        ),
        title: const Text('История заказов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, Routes.createMaintenanceRequest);
              if (result == true && mounted) {
                _loadRequests();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _clubSelector(),
                const SizedBox(height: 14),
                if (requests.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Нет заявок',
                        style: TextStyle(fontSize: 16, color: AppColors.darkGray),
                      ),
                    ),
                  )
                else
                  _ordersCard(),
              ],
            ),
    );
  }

  Widget _clubSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(clubs[selectedClub], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        trailing: PopupMenuButton<int>(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
          onSelected: (i) => setState(() => selectedClub = i),
          itemBuilder: (_) => List.generate(clubs.length, (i) => PopupMenuItem(value: i, child: Text(clubs[i]))),
        ),
      ),
    );
  }

  Widget _ordersCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary)),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(requests.length, (i) {
          final request = requests[i];
          final isOpen = expandedOrder == i;
          if (!isOpen) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == requests.length - 1 ? 0 : 12),
              child: _collapsedOrder(
                'Заявка №${request.requestId}',
                subtitle: request.clubName ?? '',
                onTap: () => setState(() => expandedOrder = i),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: i == requests.length - 1 ? 0 : 12),
            child: _expandedOrder(
              request,
              onCollapse: () => setState(() => expandedOrder = null),
            ),
          );
        }),
      ),
    );
  }

  Widget _collapsedOrder(String title, {String? subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray)),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                ],
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
        ]),
      ),
    );
  }

  Widget _expandedOrder(MaintenanceRequestResponseDto request, {required VoidCallback onCollapse}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Заявка №${request.requestId}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark))),
            InkWell(onTap: onCollapse, borderRadius: BorderRadius.circular(10), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.darkGray))),
          ]),
          const SizedBox(height: 12),
          _infoRow('Клуб', request.clubName ?? 'Не указан'),
          const SizedBox(height: 8),
          _infoRow('Статус', _getStatusText(request.status ?? 'UNKNOWN')),
          const SizedBox(height: 8),
          if (request.laneNumber != null) ...[
            _infoRow('Дорожка', request.laneNumber.toString()),
            const SizedBox(height: 8),
          ],
          if (request.managerNotes != null && request.managerNotes!.isNotEmpty)
            _infoRow('Заметки', request.managerNotes!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label + ':', style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'NEW':
        return 'Новая';
      case 'APPROVED':
        return 'Одобрена';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'DONE':
        return 'Завершена';
      case 'CLOSED':
        return 'Закрыта';
      case 'UNREPAIRABLE':
        return 'Неремонтопригодно';
      default:
        return status;
    }
  }
}
