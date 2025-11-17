import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../api/api_core.dart';
import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/purchase_orders_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../models/purchase_order_summary_dto.dart';

class SupplyArchiveScreen extends StatefulWidget {
  const SupplyArchiveScreen({super.key});

  @override
  State<SupplyArchiveScreen> createState() => _SupplyArchiveScreenState();
}

class _SupplyArchiveScreenState extends State<SupplyArchiveScreen> {
  final PurchaseOrdersRepository _ordersRepository = PurchaseOrdersRepository();
  final UserRepository _userRepository = UserRepository();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  bool _loading = true;
  bool _error = false;
  bool _forbidden = false;
  List<PurchaseOrderSummaryDto> _orders = const [];
  List<UserClub> _clubs = const [];
  int? _selectedClubId;
  String? _statusFilter;
  bool _onlyComplaints = false;
  bool _onlyReviews = false;

  static const Map<String, String> _statusLabels = {
    'COMPLETED': 'Принята',
    'PARTIALLY_COMPLETED': 'Частично принята',
    'REJECTED': 'Отклонена',
    'CANCELED': 'Отменена',
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
      _forbidden = false;
    });
    try {
      final me = await _userRepository.me();
      final clubs = resolveUserClubs(me);
      final orders = await _ordersRepository.list(
        clubId: _selectedClubId,
        archived: true,
        status: _statusFilter,
        hasComplaint: _onlyComplaints ? true : null,
        hasReview: _onlyReviews ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _orders = orders;
        _loading = false;
        _forbidden = false;
      });
    } catch (e) {
      if (!mounted) return;
      final forbidden = e is ApiException && e.statusCode == 403;
      setState(() {
        _loading = false;
        _error = !forbidden;
        _forbidden = forbidden;
      });
      if (!forbidden) {
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
        title: const Text(
          'Архив поставок',
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
    if (_forbidden) {
      return _ForbiddenState(onRetry: _load);
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
                        child: Text('Архив пуст', style: TextStyle(color: AppColors.darkGray)),
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
          DropdownButtonFormField<int?>(
            value: _selectedClubId,
            decoration: const InputDecoration(labelText: 'Клуб', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все клубы')),
              ..._clubs.map(
                (club) => DropdownMenuItem(value: club.id, child: Text(club.name ?? 'Клуб #${club.id}')),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedClubId = value);
              _load();
            },
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              FilterChip(
                label: const Text('Только с претензиями'),
                selected: _onlyComplaints,
                onSelected: (value) {
                  setState(() => _onlyComplaints = value);
                  _load();
                },
              ),
              FilterChip(
                label: const Text('Только с оценками'),
                selected: _onlyReviews,
                onSelected: (value) {
                  setState(() => _onlyReviews = value);
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrderSummaryDto order) {
    final subtitle = <String>[];
    if (order.actualDeliveryDate != null) {
      subtitle.add('Принято: ${_dateFormat.format(order.actualDeliveryDate!)}');
    }
    if (order.clubName != null) {
      subtitle.add(order.clubName!);
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
                      order.supplierName ?? 'Поставка #${order.orderId}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text('Заявка #${order.orderId}', style: const TextStyle(color: AppColors.darkGray)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
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

class _ForbiddenState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ForbiddenState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 16),
            const Text(
              'Доступ к архиву поставок ограничен.',
              style: TextStyle(color: AppColors.darkGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Убедитесь, что владелец клуба назначил вас менеджером и подтвердил доступ. '
              'После изменения прав обновите страницу.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Проверить доступ')),
          ],
        ),
      ),
    );
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
