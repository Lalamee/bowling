import 'package:flutter/material.dart';

import '../../../../api/api_core.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/warehouse_summary_dto.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import 'club_warehouse_screen.dart';

class WarehouseSelectorScreen extends StatefulWidget {
  final int? preferredClubId;

  const WarehouseSelectorScreen({super.key, this.preferredClubId});

  @override
  State<WarehouseSelectorScreen> createState() => _WarehouseSelectorScreenState();
}

class _WarehouseSelectorScreenState extends State<WarehouseSelectorScreen> {
  final _repository = InventoryRepository();
  var _isLoading = true;
  var _hasError = false;
  List<WarehouseSummaryDto> _warehouses = const [];
  bool _forbidden = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _forbidden = false;
    });
    try {
      final data = await _repository.getWarehouses();
      if (!mounted) return;
      if (data.length == 1) {
        _openWarehouse(data.first);
        return;
      }
      final sorted = List<WarehouseSummaryDto>.from(data);
      final preferredId = widget.preferredClubId;
      if (preferredId != null) {
        sorted.sort((a, b) {
          final aMatch = a.clubId == preferredId ? 0 : 1;
          final bMatch = b.clubId == preferredId ? 0 : 1;
          return aMatch.compareTo(bMatch);
        });
      }
      setState(() {
        _warehouses = sorted;
        _isLoading = false;
        _forbidden = false;
      });
    } catch (e) {
      if (!mounted) return;
      final forbidden = e is ApiException && e.statusCode == 403;
      setState(() {
        _isLoading = false;
        _hasError = !forbidden;
        _forbidden = forbidden;
      });
      if (!forbidden) {
        showApiError(context, e);
      }
    }
  }

  void _openWarehouse(WarehouseSummaryDto summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubWarehouseScreen(
          warehouseId: summary.warehouseId,
          clubId: summary.clubId,
          clubName: summary.title,
          warehouseType: summary.warehouseType,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_forbidden) {
      return const _ForbiddenWarehouseState();
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить список складов', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_warehouses.isEmpty) {
      return const Center(child: Text('Нет доступных складов'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _warehouses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = _warehouses[index];
          final subtitle = item.warehouseType == 'PERSONAL' ? 'Личный склад' : 'Клубный склад';
          return GestureDetector(
            onTap: () => _openWarehouse(item),
            child: CommonUI.card(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                        if (item.totalPositions != null) ...[
                          const SizedBox(height: 6),
                          Text('Позиций: ${item.totalPositions}', style: const TextStyle(color: AppColors.darkGray)),
                        ],
                        if (item.lowStockPositions != null)
                          Text('Низкий остаток: ${item.lowStockPositions}',
                              style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
                        if (item.reservedPositions != null)
                          Text('В резерве: ${item.reservedPositions}',
                              style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор склада'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppColors.primary))],
      ),
      body: _buildBody(),
    );
  }
}

class _ForbiddenWarehouseState extends StatelessWidget {
  const _ForbiddenWarehouseState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.darkGray),
            SizedBox(height: 16),
            Text(
              'У вас пока нет доступных складов.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Попросите владельца клуба добавить вас в команду или настройте личный склад механика.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
