import 'package:flutter/material.dart';

import '../../../../core/models/order_status.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/maintenance_request_response_dto.dart';

class ClubOrdersHistoryScreen extends StatefulWidget {
  const ClubOrdersHistoryScreen({super.key});

  @override
  State<ClubOrdersHistoryScreen> createState() => _ClubOrdersHistoryScreenState();
}

class _ClubOrdersHistoryScreenState extends State<ClubOrdersHistoryScreen> {
  final MaintenanceRepository _repository = MaintenanceRepository();
  final UserRepository _userRepository = UserRepository();

  bool _loading = true;
  bool _error = false;
  Map<String, List<MaintenanceRequestResponseDto>> _ordersByClub = const {};
  UserAccessScope? _scope;

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
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final data = await _repository.getAllRequests();
      if (!mounted) return;
      final filtered = data.where(scope.canViewOrder).toList();
      filtered.sort((a, b) {
        final aDate = a.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      final grouped = <String, List<MaintenanceRequestResponseDto>>{};
      for (final order in filtered) {
        final key = order.clubName ?? 'Без названия';
        grouped.putIfAbsent(key, () => []).add(order);
      }
      setState(() {
        _ordersByClub = grouped;
        _scope = scope;
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
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textDark),
              ),
            ),
          ),
        ),
        title: const Text(
          'Все заказы клуба',
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
    if (_ordersByClub.isEmpty) {
      return const Center(
        child: Text('Нет заказов', style: TextStyle(color: AppColors.darkGray)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _ordersByClub.length,
        itemBuilder: (_, index) {
          final clubName = _ordersByClub.keys.elementAt(index);
          final orders = _ordersByClub[clubName]!;
          return _ClubSection(
            clubName: clubName,
            orders: orders,
          );
        },
      ),
    );
  }
}

class _ClubSection extends StatelessWidget {
  final String clubName;
  final List<MaintenanceRequestResponseDto> orders;

  const _ClubSection({required this.clubName, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clubName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ...orders.map(
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGray),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заявка №${order.requestId}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildSubtitle(order),
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.darkGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(MaintenanceRequestResponseDto order) {
    final pieces = <String>[];
    if (order.status != null && order.status!.isNotEmpty) {
      pieces.add(describeOrderStatus(order.status));
    }
    if (order.requestDate != null) {
      pieces.add(_formatDate(order.requestDate!));
    }
    return pieces.join(' • ');
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
