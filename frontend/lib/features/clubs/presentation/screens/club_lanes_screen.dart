import 'package:flutter/material.dart';

import '../../../../api/api_core.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/service_history_repository.dart';
import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../models/service_history_dto.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';

class ClubLanesScreen extends StatefulWidget {
  final int clubId;
  final String? clubName;
  final int? lanesCount;

  const ClubLanesScreen({super.key, required this.clubId, this.clubName, this.lanesCount});

  @override
  State<ClubLanesScreen> createState() => _ClubLanesScreenState();
}

class _ClubLanesScreenState extends State<ClubLanesScreen> {
  final _serviceHistoryRepository = ServiceHistoryRepository();
  final _maintenanceRepository = MaintenanceRepository();
  final _clubsRepository = ClubsRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_LaneTechInfo> _lanes = const [];
  int? _selectedLaneNumber;
  bool _requestsRestricted = false;
  int? _resolvedLaneCount;

  @override
  void initState() {
    super.initState();
    _resolvedLaneCount = widget.lanesCount;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _requestsRestricted = false;
    });

    try {
      final laneCount = await _resolveLaneCount();
      final history = await _serviceHistoryRepository.getByClub(widget.clubId);
      List<MaintenanceRequestResponseDto> requests = const [];
      bool restricted = false;
      try {
        requests = await _maintenanceRepository.getRequestsByClub(widget.clubId);
      } catch (error) {
        if (error is ApiException && error.statusCode == 403) {
          restricted = true;
        } else {
          rethrow;
        }
      }

      final lanes = _buildLaneInfos(history, requests, laneCount);
      if (!mounted) return;
      setState(() {
        _lanes = lanes;
        _selectedLaneNumber = lanes.isNotEmpty ? lanes.first.laneNumber : null;
        _isLoading = false;
        _requestsRestricted = restricted;
        _resolvedLaneCount = laneCount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _requestsRestricted = false;
      });
      showApiError(context, e);
    }
  }

  Future<int?> _resolveLaneCount() async {
    if (_resolvedLaneCount != null && _resolvedLaneCount! > 0) {
      return _resolvedLaneCount;
    }
    try {
      final clubs = await _clubsRepository.getClubs();
      final match = clubs.where((club) => club.id == widget.clubId).toList();
      if (match.isNotEmpty && (match.first.lanesCount ?? 0) > 0) {
        return match.first.lanesCount;
      }
    } catch (_) {
      return _resolvedLaneCount;
    }
    return _resolvedLaneCount;
  }

  List<_LaneTechInfo> _buildLaneInfos(
    List<ServiceHistoryDto> history,
    List<MaintenanceRequestResponseDto> requests,
    int? lanesCount,
  ) {
    final laneNumbers = <int>{};
    if (lanesCount != null && lanesCount > 0) {
      for (var i = 1; i <= lanesCount; i++) {
        laneNumbers.add(i);
      }
    }
    for (final item in history) {
      final number = item.laneNumber;
      if (number != null) {
        laneNumbers.add(number);
      }
    }
    for (final item in requests) {
      final number = item.laneNumber;
      if (number != null) {
        laneNumbers.add(number);
      }
    }
    final sorted = laneNumbers.toList()..sort();
    return sorted
        .map(
          (lane) => _LaneTechInfo(
            laneNumber: lane,
            serviceHistory: _sortHistory(history.where((h) => h.laneNumber == lane).toList()),
            requests: _sortRequests(requests.where((r) => r.laneNumber == lane).toList()),
          ),
        )
        .toList();
  }

  static List<ServiceHistoryDto> _sortHistory(List<ServiceHistoryDto> items) {
    items.sort((a, b) => _historyDate(b).compareTo(_historyDate(a)));
    return items;
  }

  static DateTime _historyDate(ServiceHistoryDto dto) {
    return dto.serviceDate ?? dto.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<MaintenanceRequestResponseDto> _sortRequests(List<MaintenanceRequestResponseDto> items) {
    items.sort((a, b) => _requestDate(b).compareTo(_requestDate(a)));
    return items;
  }

  static DateTime _requestDate(MaintenanceRequestResponseDto dto) {
    return dto.requestDate ?? dto.managerDecisionDate ?? dto.completionDate ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _selectLane(int lane) {
    if (_selectedLaneNumber == lane) return;
    setState(() => _selectedLaneNumber = lane);
  }

  _LaneTechInfo? get _selectedLane {
    if (_selectedLaneNumber == null || _lanes.isEmpty) return null;
    return _lanes.firstWhere((lane) => lane.laneNumber == _selectedLaneNumber, orElse: () => _lanes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          widget.clubName ?? 'Дорожки клуба',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
        currentIndex: 2,
        onTap: (index) => BottomNavDirect.go(context, 2, index),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return _ErrorPlaceholder(onRetry: _load);
    }
    if (_lanes.isEmpty) {
      return _EmptyPlaceholder(
        title: 'Нет данных по дорожкам',
        subtitle: _resolvedLaneCount == null
            ? 'Для выбранного клуба не удалось определить количество дорожек. Добавьте данные или обратитесь в поддержку.'
            : 'Для дорожек пока нет истории обслуживания или заявок.',
      );
    }
    final selectedLane = _selectedLane;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            'Дорожки и техническая информация',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _LaneSelector(
            lanes: _lanes,
            selectedLane: _selectedLaneNumber,
            onSelect: _selectLane,
          ),
          if (_requestsRestricted) ...[
            const SizedBox(height: 12),
            const _LimitedAccessBanner(),
          ],
          const SizedBox(height: 16),
          if (selectedLane != null) ...[
            _TechnicalInfoCard(info: selectedLane),
            const SizedBox(height: 12),
            _StateCard(info: selectedLane),
            const SizedBox(height: 12),
            _HistoryCard(info: selectedLane),
          ] else ...[
            _EmptyPlaceholder(
              title: 'Выберите дорожку',
              subtitle: 'Нажмите на любую дорожку выше, чтобы увидеть технические детали и историю.',
            ),
          ],
        ],
      ),
    );
  }
}

class _LaneTechInfo {
  final int laneNumber;
  final List<ServiceHistoryDto> serviceHistory;
  final List<MaintenanceRequestResponseDto> requests;

  _LaneTechInfo({
    required this.laneNumber,
    required this.serviceHistory,
    required this.requests,
  });

  ServiceHistoryDto? get latestService => serviceHistory.isNotEmpty ? serviceHistory.first : null;

  DateTime? get nextMaintenanceDate {
    for (final item in serviceHistory) {
      if (item.nextServiceDue != null) {
        return item.nextServiceDue;
      }
    }
    return null;
  }

  bool get isMaintenanceOverdue {
    final date = nextMaintenanceDate;
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool get isMaintenanceSoon {
    final date = nextMaintenanceDate;
    if (date == null || isMaintenanceOverdue) return false;
    return date.difference(DateTime.now()).inDays <= 14;
  }

  List<_LaneEvent> get events {
    final combined = <_LaneEvent>[];
    for (final item in serviceHistory) {
      combined.add(
        _LaneEvent(
          date: item.serviceDate ?? item.createdDate,
          type: _mapServiceType(item.serviceType),
          title: item.equipmentName ?? item.serviceType,
          description: item.description,
          mechanic: item.performedByMechanicName,
          comment: item.serviceNotes,
        ),
      );
    }
    for (final request in requests) {
      combined.add(
        _LaneEvent(
          date: request.requestDate ?? request.managerDecisionDate,
          type: LaneEventType.request,
          title: 'Заявка №${request.requestId}',
          description: request.managerNotes ?? 'Текущий статус: ${request.status ?? 'не указан'}',
          mechanic: request.mechanicName,
          comment: request.status,
        ),
      );
    }
    combined.sort((a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return combined;
  }

  int? get wearPercentage {
    // TODO: запросить от бэкенда фактический уровень износа дорожки.
    return null;
  }

  List<String> get componentSerials {
    final latest = latestService;
    if (latest == null || latest.partsUsed == null) return const [];
    return latest.partsUsed!
        .map((part) => part.catalogNumber.isNotEmpty ? '${part.partName} (${part.catalogNumber})' : part.partName)
        .toList();
  }
}

enum LaneEventType { plannedMaintenance, repair, request }

LaneEventType _mapServiceType(String type) {
  switch (type) {
    case 'SCHEDULED_MAINTENANCE':
    case 'INSPECTION':
      return LaneEventType.plannedMaintenance;
    case 'REPAIR':
    case 'EMERGENCY_SERVICE':
      return LaneEventType.repair;
    default:
      return LaneEventType.plannedMaintenance;
  }
}

class _LaneStatusDescriptor {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const _LaneStatusDescriptor(this.title, this.description, this.color, this.icon);

  static _LaneStatusDescriptor fromInfo(_LaneTechInfo info) {
    if (info.isMaintenanceOverdue) {
      return const _LaneStatusDescriptor('ТО просрочено', 'Требуется внимание и планирование работ', Colors.red, Icons.error_outline);
    }
    if (info.isMaintenanceSoon) {
      return const _LaneStatusDescriptor('Скоро плановое ТО', 'Запланируйте обслуживание заранее', Colors.orange, Icons.watch_later_outlined);
    }
    return const _LaneStatusDescriptor('ТО в норме', 'Обслуживание выполнено вовремя', Colors.green, Icons.check_circle_outline);
  }
}

class _LaneSelector extends StatelessWidget {
  final List<_LaneTechInfo> lanes;
  final int? selectedLane;
  final ValueChanged<int> onSelect;

  const _LaneSelector({required this.lanes, required this.selectedLane, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: lanes.map((lane) => _buildChip(lane)).toList(),
    );
  }

  Widget _buildChip(_LaneTechInfo info) {
    final descriptor = _LaneStatusDescriptor.fromInfo(info);
    final isSelected = info.laneNumber == selectedLane;
    return GestureDetector(
      onTap: () => onSelect(info.laneNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? descriptor.color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? descriptor.color : AppColors.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: descriptor.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'Дорожка ${info.laneNumber}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textDark : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalInfoCard extends StatelessWidget {
  final _LaneTechInfo info;

  const _TechnicalInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final latest = info.latestService;
    final components = info.componentSerials;
    return CommonUI.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Техническая информация',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Модель оборудования', value: latest?.equipmentName ?? 'Нет данных'),
          const SizedBox(height: 8),
          // TODO: добавить модель года выпуска и серийные номера от бэкенда.
          _InfoRow(label: 'Год выпуска', value: '—'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Серийный номер пинсеттера', value: '—'),
          const SizedBox(height: 8),
          if (components.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Электронные компоненты', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: components
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
                        ),
                      )
                      .toList(),
                ),
              ],
            )
          else
            _InfoRow(label: 'Электронные компоненты', value: 'Нет данных'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Уровень износа', value: info.wearPercentage != null ? '${info.wearPercentage}% ' : 'Нет данных'),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final _LaneTechInfo info;

  const _StateCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final descriptor = _LaneStatusDescriptor.fromInfo(info);
    return CommonUI.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Состояние и ТО',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(descriptor.icon, color: descriptor.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descriptor.title, style: TextStyle(fontWeight: FontWeight.w600, color: descriptor.color)),
                    Text(descriptor.description, style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Дата следующего ТО',
            value: info.nextMaintenanceDate != null ? _formatDate(info.nextMaintenanceDate!) : 'Нет данных',
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'ТО просрочено', value: info.isMaintenanceOverdue ? 'Да' : 'Нет'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Скоро плановое ТО', value: info.isMaintenanceSoon ? 'Да' : 'Нет'),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _LaneTechInfo info;

  const _HistoryCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final events = info.events;
    return CommonUI.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'История обслуживания и заявок',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text('Нет записей', style: TextStyle(color: AppColors.darkGray))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _LaneEventTile(event: events[index]),
            ),
        ],
      ),
    );
  }
}

class _LaneEventTile extends StatefulWidget {
  final _LaneEvent event;

  const _LaneEventTile({required this.event});

  @override
  State<_LaneEventTile> createState() => _LaneEventTileState();
}

class _LaneEventTileState extends State<_LaneEventTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final descriptor = _LaneEventDescriptor.of(widget.event.type);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        initiallyExpanded: false,
        onExpansionChanged: (value) => setState(() => _open = value),
        title: Row(
          children: [
            Icon(descriptor.icon, color: descriptor.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  if (widget.event.date != null)
                    Text(
                      _formatDate(widget.event.date!),
                      style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                    ),
                ],
              ),
            ),
          ],
        ),
        subtitle: !_open
            ? Text(
                descriptor.title,
                style: TextStyle(fontSize: 12, color: descriptor.color),
              )
            : null,
        children: [
          _InfoRow(label: 'Тип', value: descriptor.title),
          if (widget.event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.event.description, style: const TextStyle(color: AppColors.darkGray)),
          ],
          if (widget.event.mechanic != null && widget.event.mechanic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Механик', value: widget.event.mechanic!),
          ],
          if (widget.event.comment != null && widget.event.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Комментарий', value: widget.event.comment!),
          ],
        ],
      ),
    );
  }
}

class _LaneEventDescriptor {
  final LaneEventType type;
  final String title;
  final Color color;
  final IconData icon;

  const _LaneEventDescriptor(this.type, this.title, this.color, this.icon);

  static _LaneEventDescriptor of(LaneEventType type) {
    switch (type) {
      case LaneEventType.plannedMaintenance:
        return const _LaneEventDescriptor(LaneEventType.plannedMaintenance, 'Плановое ТО', Colors.green, Icons.event_available);
      case LaneEventType.repair:
        return const _LaneEventDescriptor(LaneEventType.repair, 'Ремонт', AppColors.primary, Icons.handyman_outlined);
      case LaneEventType.request:
        return const _LaneEventDescriptor(LaneEventType.request, 'Заявка', Colors.orange, Icons.build_circle_outlined);
    }
  }
}

class _LaneEvent {
  final DateTime? date;
  final LaneEventType type;
  final String title;
  final String description;
  final String? mechanic;
  final String? comment;

  _LaneEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    this.mechanic,
    this.comment,
  });
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        ),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPlaceholder({required this.onRetry});

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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC48B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.lock_outline, color: Color(0xFFD17A00)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'История заявок клуба недоступна для вашей роли. Обратитесь к владельцу клуба, '
              'чтобы подтвердить доступ менеджера или пригласить вас в клуб.',
              style: TextStyle(color: Color(0xFFD17A00), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPlaceholder({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_stream_rounded, size: 64, color: AppColors.darkGray),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}
