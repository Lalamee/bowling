import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/order_status.dart';
import '../../../../core/models/user_club.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import 'order_summary_screen.dart';

class ManagerOrdersHistoryScreen extends StatefulWidget {
  const ManagerOrdersHistoryScreen({super.key});

  @override
  State<ManagerOrdersHistoryScreen> createState() => _ManagerOrdersHistoryScreenState();
}

class _ManagerOrdersHistoryScreenState extends State<ManagerOrdersHistoryScreen> {
  final MaintenanceRepository _repository = MaintenanceRepository();
  final UserRepository _userRepository = UserRepository();

  bool _loading = true;
  bool _error = false;
  List<MaintenanceRequestResponseDto> _orders = const [];
  int? _expandedIndex;
  List<UserClub> _clubs = const [];
  int? _selectedClubId;
  OrderStatusType? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  static const List<OrderStatusType> _statusOptions = kOrderStatusFilterOrder;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final clubs = resolveUserClubs(me);
      final data = await _repository.getAllRequests();
      if (!mounted) return;
      final visible = data.where(scope.canViewOrder).toList();
      visible.sort((a, b) {
        final aDate = a.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _orders = visible;
        _clubs = clubs;
        if (_selectedClubId != null && !_clubs.any((club) => club.id == _selectedClubId)) {
          _selectedClubId = null;
        }
        _expandedIndex = null;
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
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildFilters(),
            const SizedBox(height: 40),
            const Center(
              child: Text('Заказы отсутствуют', style: TextStyle(color: AppColors.darkGray)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFilters(),
            );
          }
          final item = orders[index - 1];
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

  List<MaintenanceRequestResponseDto> get _filteredOrders {
    Iterable<MaintenanceRequestResponseDto> base = _orders;
    final clubId = _selectedClubId;
    if (clubId != null) {
      base = base.where((order) => order.clubId == clubId);
    }
    final statusFilter = _selectedStatus;
    if (statusFilter != null) {
      base = base.where((order) => statusFilter.matches(order.status)).toList();
    }
    final query = _normalize(_searchQuery);
    if (query.isNotEmpty) {
      base = base.where((order) => _matchesQuery(order, query));
    }
    return base.toList();
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClubDropdown(),
        const SizedBox(height: 12),
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildStatusChips(),
      ],
    );
  }

  Widget _buildClubDropdown() {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('Все клубы')),
      ..._clubs.map(
        (club) => DropdownMenuItem<int?>(
          value: club.id,
          child: Text(club.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedClubId,
          isExpanded: true,
          items: items,
          onChanged: (value) {
            setState(() {
              _selectedClubId = value;
              _expandedIndex = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Поиск по номеру заявки, клубу или заметкам',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), () {
            if (!mounted) return;
            setState(() {
              _searchQuery = value;
              _expandedIndex = null;
            });
          });
        },
      ),
    );
  }

  Widget _buildStatusChips() {
    TextStyle labelStyle(bool selected) => TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const side = BorderSide(color: AppColors.lightGray);

    final chips = <Widget>[
      ChoiceChip(
        label: const Text('Все'),
        selected: _selectedStatus == null,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        shape: shape,
        side: side,
        labelStyle: labelStyle(_selectedStatus == null),
        onSelected: (_) {
          setState(() {
            _selectedStatus = null;
            _expandedIndex = null;
          });
        },
      ),
      ..._statusOptions.map((option) {
        final selected = option == _selectedStatus;
        return ChoiceChip(
          label: Text(option.label),
          selected: selected,
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white,
          shape: shape,
          side: side,
          labelStyle: labelStyle(selected),
          onSelected: (_) {
            setState(() {
              _selectedStatus = selected ? null : option;
              _expandedIndex = null;
            });
          },
        );
      }),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  bool _matchesQuery(MaintenanceRequestResponseDto order, String query) {
    final buffer = StringBuffer()
      ..write(order.requestId)
      ..write(' ')
      ..write(order.clubName ?? '')
      ..write(' ')
      ..write(order.status ?? '')
      ..write(' ')
      ..write(order.managerNotes ?? '');
    if (order.laneNumber != null) {
      buffer
        ..write(' ')
        ..write(order.laneNumber);
    }
    final haystack = _normalize(buffer.toString());
    return haystack.contains(query);
  }

  String _normalize(String value) => value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
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
      subtitle.add(describeOrderStatus(order.status));
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
            _InfoRow(label: 'Статус', value: describeOrderStatus(order.status)),
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
                          child: Text('Статус: ${describeOrderStatus(part.status)}',
                              style: const TextStyle(color: AppColors.darkGray)),
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

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
