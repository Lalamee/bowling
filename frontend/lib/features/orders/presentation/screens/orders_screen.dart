import 'package:flutter/material.dart';

import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import 'order_summary_screen.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _maintenanceRepository = MaintenanceRepository();
  final _userRepository = UserRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _requests = [];
  int? _selectedLane;
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Не удалось загрузить заказы',
                        style: TextStyle(color: AppColors.darkGray),
                      ),
                    ),
                  ],
                );
              }
              if (_requests.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Заказов нет',
                        style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                      ),
                    ),
                  ],
                );
              }

              final requests = _filteredRequests;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Заказы',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _load,
                      ),
                    ],
                  ),
                  if (_laneOptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _laneDropdown(),
                  ],
                  const SizedBox(height: 12),
                  ...List.generate(requests.length, (index) {
                    final request = requests[index];
                    final isExpanded = _expandedIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == requests.length - 1 ? 0 : 12),
                      child: _OrderCard(
                        request: request,
                        expanded: isExpanded,
                        onToggle: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onOpenSummary: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderSummaryScreen(
                                orderNumber: 'Заявка №${request.requestId}',
                                order: request,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      if (!mounted) return;
      final mechanicId = (me?['id'] as num?)?.toInt();
      if (mechanicId == null) {
        setState(() {
          _requests = [];
          _selectedLane = null;
          _expandedIndex = null;
          _isLoading = false;
        });
        showSnack(context, 'Не удалось определить пользователя');
        return;
      }
      final requests = await _maintenanceRepository.requestsForMechanic(mechanicId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        final lanes = _laneOptions;
        if (!lanes.contains(_selectedLane)) {
          _selectedLane = null;
        }
        _expandedIndex = null;
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

  List<int> get _laneOptions {
    final lanes = _requests
        .map((e) => e.laneNumber)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    return lanes;
  }

  List<MaintenanceRequestResponseDto> get _filteredRequests {
    final lanes = _laneOptions;
    final selected = _selectedLane;
    if (selected == null || lanes.isEmpty) {
      return _requests;
    }
    return _requests.where((element) => element.laneNumber == selected).toList();
  }

  Widget _laneDropdown() {
    final lanes = _laneOptions;
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedLane,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkGray),
          hint: const Text('Все дорожки', style: TextStyle(color: AppColors.textDark)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Все дорожки')),
            ...lanes.map(
              (lane) => DropdownMenuItem<int?>(
                value: lane,
                child: Text('Дорожка $lane', style: const TextStyle(color: AppColors.textDark)),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _selectedLane = v;
            _expandedIndex = null;
          }),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MaintenanceRequestResponseDto request;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenSummary;

  const _OrderCard({
    required this.request,
    required this.expanded,
    required this.onToggle,
    required this.onOpenSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: expanded ? AppColors.primary : AppColors.lightGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            title: Text(
              'Заявка №${request.requestId}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.clubName != null && request.clubName!.isNotEmpty)
                  Text(request.clubName!, style: const TextStyle(color: AppColors.darkGray)),
                if (request.laneNumber != null)
                  Text('Дорожка ${request.laneNumber}', style: const TextStyle(color: AppColors.darkGray)),
                if (request.status != null)
                  Text(_statusName(request.status!), style: const TextStyle(color: AppColors.darkGray)),
              ],
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.darkGray),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (request.managerNotes != null && request.managerNotes!.isNotEmpty) ...[
                    const Text('Заметки менеджера', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(request.managerNotes!, style: const TextStyle(color: AppColors.darkGray)),
                    const SizedBox(height: 12),
                  ],
                  const Text('Детали заказа', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  if (request.requestedParts.isEmpty)
                    const Text('Нет деталей', style: TextStyle(color: AppColors.darkGray))
                  else ...request.requestedParts.map(
                      (part) => Container(
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
                      ),
                    ),
                  const SizedBox(height: 12),
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
            ),
        ],
      ),
    );
  }

  static String _statusName(String status) {
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
        return 'Статус: $status';
    }
  }
}
