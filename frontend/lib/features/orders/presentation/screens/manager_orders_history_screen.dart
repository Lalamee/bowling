import 'package:flutter/material.dart';

import '../../../../core/services/access_guard.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import 'order_summary_screen.dart';

class ManagerOrdersHistoryScreen extends StatefulWidget {
  const ManagerOrdersHistoryScreen({super.key});

  @override
  State<ManagerOrdersHistoryScreen> createState() => _ManagerOrdersHistoryScreenState();
}

class _ManagerOrdersHistoryScreenState extends State<ManagerOrdersHistoryScreen> {
  final MaintenanceRepository _repository = MaintenanceRepository();

  bool _loading = true;
  bool _error = false;
  List<MaintenanceRequestResponseDto> _orders = const [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final guard = AccessGuardImpl();
      final snapshot = await guard.ensureLoaded();
      final data = await _repository.getAllRequests();
      if (!mounted) return;
      final filtered = <MaintenanceRequestResponseDto>[];
      for (final order in data) {
        if (snapshot.role.isAdmin) {
          filtered.add(order);
          continue;
        }
        final clubId = order.clubId?.toString();
        if (clubId != null && snapshot.allowedClubIds.contains(clubId)) {
          filtered.add(order);
        }
      }
      filtered.sort((a, b) {
        final aDate = a.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _orders = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
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
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
              ),
            ),
          ),
        ),
        title: const Text(
          'Заказы',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить историю заказов', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Text('Нет заказов для ваших клубов', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = _orders[index];
          final isExpanded = _expandedIndex == index;
          if (!isExpanded) {
            return _CollapsedOrderCard(
              order: item,
              onTap: () => setState(() => _expandedIndex = index),
            );
          }
          return _ExpandedOrderCard(
            order: item,
            onCollapse: () => setState(() => _expandedIndex = null),
            onOpenSummary: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSummaryScreen(order: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CollapsedOrderCard extends StatelessWidget {
  final MaintenanceRequestResponseDto order;
  final VoidCallback onTap;

  const _CollapsedOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      subtitle.add(order.clubName!);
    }
    if (order.status != null && order.status!.isNotEmpty) {
      subtitle.add(_statusName(order.status!));
    }
    if (order.requestDate != null) {
      subtitle.add(_formatDate(order.requestDate!));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заявка №${order.requestId}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle.join(' • '),
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
          ],
        ),
      ),
    );
  }
}

class _ExpandedOrderCard extends StatelessWidget {
  final MaintenanceRequestResponseDto order;
  final VoidCallback onCollapse;
  final VoidCallback onOpenSummary;

  const _ExpandedOrderCard({
    required this.order,
    required this.onCollapse,
    required this.onOpenSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
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
              IconButton(
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.clubName != null && order.clubName!.isNotEmpty)
            _InfoRow(label: 'Клуб', value: order.clubName!),
          if (order.laneNumber != null)
            _InfoRow(label: 'Дорожка', value: order.laneNumber.toString()),
          if (order.status != null && order.status!.isNotEmpty)
            _InfoRow(label: 'Статус', value: _statusName(order.status!)),
          if (order.requestDate != null)
            _InfoRow(label: 'Создано', value: _formatDate(order.requestDate!)),
          const SizedBox(height: 12),
          const Text(
            'Детали заказа',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          if (order.requestedParts.isEmpty)
            const Text('Детали отсутствуют', style: TextStyle(color: AppColors.darkGray))
          else
            Column(
              children: order.requestedParts.map((part) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partName ?? part.catalogNumber ?? 'Неизвестная деталь',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      if (part.catalogNumber != null && part.catalogNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Каталожный номер: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
                        ),
                      if (part.inventoryLocation != null && part.inventoryLocation!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Локация: ${part.inventoryLocation}', style: const TextStyle(color: AppColors.darkGray)),
                        ),
                      if (part.quantity != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
                        ),
                      if (part.status != null && part.status!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Статус: ${_statusName(part.status!)}', style: const TextStyle(color: AppColors.darkGray)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onOpenSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Подробнее'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusName(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return 'Одобрено';
    case 'REJECTED':
      return 'Отклонено';
    case 'IN_PROGRESS':
      return 'В работе';
    case 'COMPLETED':
      return 'Завершено';
    default:
      return status;
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
