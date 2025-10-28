import 'package:flutter/material.dart';
import '../../../../core/models/order_status.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/routing/routes.dart';

/// Экран просмотра всех заявок на обслуживание (интегрирован с API)
class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() => _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  final _repo = MaintenanceRepository();
  final _userRepo = UserRepository();
  List<MaintenanceRequestResponseDto> requests = [];
  bool isLoading = true;
  OrderStatusType? _selectedStatus;
  UserAccessScope? _scope;
  static const List<OrderStatusType> _statusFilters = kOrderStatusFilterOrder;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);
    try {
      _scope ??= await UserAccessScope.fromProfile(await _userRepo.me());
      final scope = _scope!;
      final filter = _selectedStatus;

      List<MaintenanceRequestResponseDto> data;
      if (filter == null) {
        data = await _repo.getAllRequests();
      } else if (filter.backendKeys.length == 1) {
        data = await _repo.getRequestsByStatus(filter.backendKeys.first);
      } else {
        data = await _repo.getAllRequests();
      }

      if (mounted) {
        setState(() {
          final scoped = scope.isAdmin ? data : data.where(scope.canViewOrder).toList();
          requests = filter == null
              ? scoped
              : scoped.where((order) => filter.matches(order.status)).toList();
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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Заявки на обслуживание',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
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
      body: Column(
        children: [
          // Фильтр по статусу
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final isSelected = _selectedStatus == null;
                  return FilterChip(
                    label: const Text('Все'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = null;
                      });
                      _loadRequests();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }

                final status = _statusFilters[i - 1];
                final isSelected = _selectedStatus == status;
                return FilterChip(
                  label: Text(status.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                    _loadRequests();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),

          // Список заявок
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: AppColors.darkGray),
                            const SizedBox(height: 16),
                            Text(
                              'Нет заявок',
                              style: TextStyle(fontSize: 16, color: AppColors.darkGray),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _RequestCard(request: requests[i]),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }

}

class _RequestCard extends StatelessWidget {
  final MaintenanceRequestResponseDto request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Навигация к детальному просмотру
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Заявка №${request.requestId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(request.status ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (request.managerNotes != null && request.managerNotes!.isNotEmpty) ...[
                  Text(
                    request.managerNotes!,
                    style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    if (request.clubName != null) ...[
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.clubName!,
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (request.laneNumber != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.straighten, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Text(
                        'Дорожка ${request.laneNumber}',
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                      ),
                    ],
                  ],
                ),
                if (request.requestDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.darkGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(request.requestDate!),
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) => describeOrderStatus(status);

  Color _getStatusColor(String status) {
    final parsed = OrderStatusType.fromRaw(status);
    if (parsed == null) {
      return AppColors.darkGray;
    }
    switch (parsed) {
      case OrderStatusType.pending:
        return AppColors.darkGray;
      case OrderStatusType.confirmed:
        return Colors.blue;
      case OrderStatusType.archived:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
