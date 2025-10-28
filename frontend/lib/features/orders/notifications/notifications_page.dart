import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/repositories/user_repository.dart';
import '../../../core/services/authz/acl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/net_ui.dart';
import '../../../models/maintenance_request_response_dto.dart';
import '../notifications/notifications_badge_controller.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _badgeController = NotificationsBadgeController();
  final _userRepository = UserRepository();
  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

  UserAccessScope? _scope;
  bool _loading = true;
  bool _error = false;

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
      final scope = await UserAccessScope.fromProfile(me);
      if (scope.role != 'manager' && scope.role != 'owner') {
        if (!mounted) return;
        setState(() {
          _scope = scope;
          _loading = false;
        });
        return;
      }
      await _badgeController.ensureInitialized(scope);
      if (!mounted) return;
      setState(() {
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

  Future<void> _refresh() async {
    await _badgeController.refresh();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _markAsRead() async {
    await _badgeController.markAllAsRead();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Оповещения',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(scope),
    );
  }

  Widget _buildBody(UserAccessScope? scope) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить оповещения', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
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

    if (scope == null || (scope.role != 'manager' && scope.role != 'owner')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Оповещения доступны только для менеджеров и владельцев клубов',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkGray),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, _) {
        final items = _badgeController.newOrders;

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Новых оповещений нет',
                    style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markAsRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Отметить все как прочитано'),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final order = items[index];
                    final updatedAt = _resolveUpdatedAt(order);
                    final subtitle = _buildSubtitle(order, updatedAt);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Заявка №${order.requestId}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(
                                subtitle,
                                style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildSubtitle(MaintenanceRequestResponseDto order, DateTime? updatedAt) {
    final parts = <String>[];
    if (order.clubName != null && order.clubName!.isNotEmpty) {
      parts.add(order.clubName!);
    }
    if (order.status != null && order.status!.isNotEmpty) {
      parts.add(order.status!);
    }
    if (updatedAt != null) {
      parts.add(_dateFormatter.format(updatedAt));
    }
    return parts.join(' • ');
  }

  DateTime? _resolveUpdatedAt(MaintenanceRequestResponseDto order) {
    DateTime? latest;
    void consider(DateTime? value) {
      if (value == null) return;
      if (latest == null || value.isAfter(latest!)) {
        latest = value;
      }
    }

    consider(order.managerDecisionDate);
    consider(order.completionDate);
    consider(order.requestDate);
    for (final part in order.requestedParts) {
      consider(part.deliveryDate);
      consider(part.issueDate);
      consider(part.orderDate);
    }

    return latest;
  }
}
