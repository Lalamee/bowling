import 'package:flutter/material.dart';

import '../../../core/repositories/maintenance_repository.dart';
import '../../../core/theme/colors.dart';
import '../../../models/admin_help_request_dto.dart';
import '../../../models/maintenance_request_response_dto.dart';
import '../presentation/screens/order_summary_screen.dart';
import '../../../core/theme/typography_extension.dart';
import '../../../core/utils/net_ui.dart';

class AdminHelpRequestsScreen extends StatefulWidget {
  const AdminHelpRequestsScreen({super.key});

  @override
  State<AdminHelpRequestsScreen> createState() => _AdminHelpRequestsScreenState();
}

class _AdminHelpRequestsScreenState extends State<AdminHelpRequestsScreen> {
  final _maintenanceRepository = MaintenanceRepository();
  bool _loading = true;
  bool _error = false;
  List<AdminHelpRequestDto> _items = const [];

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
      final data = await _maintenanceRepository.getAdminHelpRequests();
      if (!mounted) return;
      setState(() {
        _items = data;
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

  Future<void> _openRequest(AdminHelpRequestDto dto) async {
    final detail = await _maintenanceRepository.getById(dto.requestId);
    if (detail == null || !mounted) {
      showSnack(context, 'Не удалось открыть заявку ${dto.requestId}');
      return;
    }
    final updated = await Navigator.push<MaintenanceRequestResponseDto>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          orderNumber: 'Заявка №${detail.requestId}',
          order: detail,
          canConfirm: false,
          canComplete: false,
          canRequestHelp: false,
          canResolveHelp: true,
          onOrderUpdated: (value) {
            setState(() {
              _items = _items
                  .where((element) => !(element.requestId == value.requestId &&
                      value.requestedParts.every((p) => p.helpRequested != true)))
                  .toList();
            });
          },
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _items = _items
            .where((element) => element.requestId != updated.requestId ||
                updated.requestedParts.any((p) => p.helpRequested == true))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы помощи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppTypography t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить запросы помощи', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Активных запросов помощи нет', style: TextStyle(color: AppColors.darkGray)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              title: Text('Заявка №${item.requestId}', style: t.formLabel),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Позиция: ${item.partId}', style: t.formInput),
                  if (item.laneNumber != null) Text('Дорожка: ${item.laneNumber}', style: t.formInput),
                  if (item.partStatus != null)
                    Text('Статус позиции: ${_partStatusLabel(item.partStatus)}', style: t.formInput),
                  Text(
                    item.helpRequested == true
                        ? 'Флаг помощи: включен'
                        : 'Флаг помощи: снят',
                    style: t.formInput,
                  ),
                  if (item.managerNotes != null && item.managerNotes!.isNotEmpty)
                    Text(item.managerNotes!, style: t.formInput),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                onPressed: () => _openRequest(item),
              ),
            ),
          );
        },
      ),
    );
  }

  String _partStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVAL_PENDING':
        return 'Ожидает подтверждения';
      case 'APPROVAL_REJECTED':
        return 'Отклонено';
      case 'APPROVED':
        return 'Одобрено';
      case 'DELIVERED':
        return 'Доставлено';
      case 'REQUESTED':
        return 'Запрошено';
      case 'IN_PROGRESS':
        return 'В работе';
      default:
        return status ?? '—';
    }
  }
}
