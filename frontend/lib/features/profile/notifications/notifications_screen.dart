import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/access_guard.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsServiceImpl _service = NotificationsServiceImpl();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  List<MaintenanceRequestResponseDto> _orders = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore || _loading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      if (reset) {
        _loading = true;
        _error = false;
        _hasMore = true;
        _currentPage = 1;
        _orders = const [];
      } else {
        _loadingMore = true;
      }
    });

    try {
      final pageToLoad = reset ? 1 : _currentPage + 1;
      final data = await _service.fetchNewOrders(page: pageToLoad);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _orders = data;
          _loading = false;
        } else {
          _orders = List.of(_orders)..addAll(data);
          _loadingMore = false;
        }
        if (data.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage = pageToLoad;
          _hasMore = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _loading = false;
          _error = true;
        } else {
          _loadingMore = false;
        }
      });
      debugPrint('Notifications load failed: $e');
    }
  }

  Future<void> _refresh() => _load(reset: true);

  Future<void> _markAllSeen() async {
    await _service.markAllSeen();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Новые заказы отмечены как просмотренные')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Оповещения',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: _orders.isEmpty ? null : _markAllSeen,
            child: const Text('Прочитано'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) => BottomNavDirect.go(context, 2, i),
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
            const Text('Не удалось загрузить уведомления', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      final guard = AccessGuardImpl();
      final allowedClubs = guard.allowedClubIdsForCurrent();
      final message = allowedClubs.isEmpty && !guard.isAdmin()
          ? 'Нет заказов для ваших клубов'
          : 'Новых заказов нет';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            style: const TextStyle(color: AppColors.darkGray),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final itemCount = _orders.length + 1 + (_loadingMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Найдено ${_orders.length}',
                style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
              ),
            );
          }
          final adjustedIndex = index - 1;
          if (adjustedIndex >= _orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = _orders[adjustedIndex];
          return _NotificationCard(order: order, dateFormat: _dateFormat);
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final MaintenanceRequestResponseDto order;
  final DateFormat dateFormat;

  const _NotificationCard({required this.order, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final createdAt = order.requestDate != null ? dateFormat.format(order.requestDate!) : '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Заявка №${order.requestId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  createdAt,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.clubName ?? 'Клуб не указан',
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            if (order.status != null) ...[
              const SizedBox(height: 6),
              Text(
                'Статус: ${order.status}',
                style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
