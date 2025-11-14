import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/purchase_orders_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../models/purchase_order_summary_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';

class SupplyAcceptanceScreen extends StatefulWidget {
  const SupplyAcceptanceScreen({super.key});

  @override
  State<SupplyAcceptanceScreen> createState() => _SupplyAcceptanceScreenState();
}

class _SupplyAcceptanceScreenState extends State<SupplyAcceptanceScreen> {
  final PurchaseOrdersRepository _ordersRepository = PurchaseOrdersRepository();
  final UserRepository _userRepository = UserRepository();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  bool _loading = true;
  bool _error = false;
  List<PurchaseOrderSummaryDto> _orders = const [];
  List<UserClub> _clubs = const [];
  int? _selectedClubId;
  String? _statusFilter;

  static const Map<String, String> _statusLabels = {
    'PENDING': 'Ожидает',
    'CONFIRMED': 'Подтверждена',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final me = await _userRepository.me();
      final clubs = resolveUserClubs(me);
      final orders = await _ordersRepository.list(
        clubId: _selectedClubId,
        archived: false,
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _orders = orders;
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
        title: const Text(
          'Приёмка поставок',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _load,
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
      return _ErrorState(onRetry: _load);
    }
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('Нет поставок, ожидающих приёмку', style: TextStyle(color: AppColors.darkGray)),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemBuilder: (_, index) => _buildOrderCard(_orders[index]),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _orders.length,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedClubId,
                  decoration: const InputDecoration(labelText: 'Клуб', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все клубы')),
                    ..._clubs.map(
                      (club) => DropdownMenuItem(
                        value: club.id,
                        child: Text(club.name ?? 'Клуб #${club.id}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedClubId = value);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _statusLabels.entries
                .map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: _statusFilter == entry.key,
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = _statusFilter == entry.key ? null : entry.key;
                      });
                      _load();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrderSummaryDto order) {
    final supplier = order.supplierName ?? 'Поставщик #${order.orderId}';
    final subtitle = <String>[];
    if (order.expectedDeliveryDate != null) {
      subtitle.add('Ожидалось: ${_dateFormat.format(order.expectedDeliveryDate!)}');
    }
    if (order.orderDate != null) {
      subtitle.add('Заявка: ${_dateFormat.format(order.orderDate!)}');
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      supplier,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text('Заявка #${order.orderId}', style: const TextStyle(color: AppColors.darkGray)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle.join(' • '), style: const TextStyle(color: AppColors.darkGray)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _StatusBadge(label: _statusLabels[order.status] ?? order.status, color: AppColors.primary),
                  if (order.hasComplaint)
                    const _StatusBadge(label: 'Есть претензия', color: Colors.redAccent),
                  if (order.hasReview)
                    const _StatusBadge(label: 'Есть оценка', color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(PurchaseOrderSummaryDto order) {
    Navigator.pushNamed(
      context,
      Routes.supplyOrderDetails,
      arguments: SupplyOrderDetailsArgs(orderId: order.orderId, summary: order),
    ).then((_) => _load());
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
          const SizedBox(height: 12),
          const Text('Не удалось загрузить данные', style: TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
