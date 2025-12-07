import 'package:flutter/material.dart';

import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/owner_dashboard_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/notifications_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/utils/help_request_status_helper.dart';
import '../../../../models/notification_event_dto.dart';
import '../../../../models/service_journal_entry_dto.dart';
import '../../../../models/technical_info_dto.dart';
import '../../../../models/warning_dto.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../orders/presentation/screens/order_summary_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final int? initialClubId;

  const OwnerDashboardScreen({super.key, this.initialClubId});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with SingleTickerProviderStateMixin {
  final _userRepository = UserRepository();
  final _repository = OwnerDashboardRepository();
  final _notificationsRepository = NotificationsRepository();
  final _maintenanceRepository = MaintenanceRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<UserClub> _clubs = const [];
  int? _selectedClubId;

  List<TechnicalInfoDto> _technical = const [];
  List<ServiceJournalEntryDto> _journal = const [];
  List<WarningDto> _warnings = const [];
  List<NotificationEventDto> _notifications = const [];

  int? _laneFilter;
  String? _workTypeFilter;
  String? _statusFilter;
  DateTimeRange? _dateRange;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClubs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      final clubs = resolveUserClubs(me);
      int? selectedId;
      if (widget.initialClubId != null && clubs.any((c) => c.id == widget.initialClubId)) {
        selectedId = widget.initialClubId;
      } else if (clubs.isNotEmpty) {
        selectedId = clubs.first.id;
      }
      setState(() {
        _clubs = clubs;
        _selectedClubId = selectedId;
      });
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      showApiError(context, e);
    }
  }

  Future<void> _loadData() async {
    if (_selectedClubId == null && _clubs.isNotEmpty) {
      setState(() => _selectedClubId = _clubs.first.id);
    }
    if (_selectedClubId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.technicalInfo(clubId: _selectedClubId),
        _repository.serviceJournal(
          clubId: _selectedClubId,
          laneNumber: _laneFilter,
          start: _dateRange?.start,
          end: _dateRange?.end,
          workType: _workTypeFilter,
          status: _statusFilter,
        ),
        _repository.warnings(clubId: _selectedClubId),
        _notificationsRepository.fetchNotifications(clubId: _selectedClubId),
      ]);
      if (!mounted) return;
      setState(() {
        _technical = results[0] as List<TechnicalInfoDto>;
        _journal = results[1] as List<ServiceJournalEntryDto>;
        _warnings = results[2] as List<WarningDto>;
        _notifications = results[3] as List<NotificationEventDto>;
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

  void _selectClub(int? clubId) {
    if (clubId == null || clubId == _selectedClubId) return;
    setState(() => _selectedClubId = clubId);
    _loadData();
  }

  void _updateLaneFilter(String value) {
    final parsed = int.tryParse(value.trim());
    _laneFilter = parsed;
    _loadData();
  }

  void _updateWorkType(String? value) {
    setState(() => _workTypeFilter = value?.isEmpty ?? true ? null : value);
    _loadData();
  }

  void _updateStatus(String? value) {
    setState(() => _statusFilter = value?.isEmpty ?? true ? null : value);
    _loadData();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  Widget _buildClubSelector() {
    if (_clubs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Для вашего аккаунта нет доступных клубов', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return DropdownButton<int>(
      value: _selectedClubId,
      items: _clubs
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => _selectClub(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Техинфо и ТО',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh, color: AppColors.primary)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkGray,
          tabs: const [
            Tab(text: 'Тех. инфо'),
            Tab(text: 'Журнал'),
            Tab(text: 'Предупр.'),
            Tab(text: 'Оповещения'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('Клуб:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildClubSelector()),
                ],
              ),
            ),
            Expanded(child: _buildTabBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) => BottomNavDirect.go(context, 2, i),
      ),
    );
  }

  Widget _buildTabBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить данные кабинета', style: TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadClubs,
              child: const Text('Повторить'),
            )
          ],
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTechnicalTab(),
        _buildJournalTab(),
        _buildWarningsTab(),
        _buildNotificationsTab(),
      ],
    );
  }

  Widget _buildTechnicalTab() {
    if (_technical.isEmpty) {
      return const Center(
        child: Text('Нет данных по оборудованию', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _technical.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = _technical[i];
          return CommonUI.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.model ?? 'Оборудование',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                    ),
                    if (item.conditionPercentage != null)
                      Chip(
                        label: Text('${item.conditionPercentage}% состояния'),
                        backgroundColor: AppColors.background,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('Тип', item.equipmentType ?? '—'),
                _infoRow('Производитель', item.manufacturer ?? '—'),
                _infoRow('Год выпуска', item.productionYear?.toString() ?? '—'),
                _infoRow('Серийный номер', item.serialNumber ?? '—'),
                _infoRow('Статус', item.status ?? '—'),
                _infoRow('Плановое ТО', _formatDate(item.nextMaintenanceDate) ?? '—'),
                _infoRow('Последнее ТО', _formatDate(item.lastMaintenanceDate) ?? '—'),
                _infoRow('Дата покупки', _formatDate(item.purchaseDate) ?? '—'),
                _infoRow('Гарантия до', _formatDate(item.warrantyUntil) ?? '—'),
                const SizedBox(height: 10),
                if (item.components.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Узлы и компоненты', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: item.components
                            .map((c) => Chip(label: Text(c.name), backgroundColor: AppColors.background))
                            .toList(),
                      ),
                    ],
                  ),
                if (item.schedules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('График ТО', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...item.schedules.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            s.critical == true ? Icons.warning_amber_rounded : Icons.event_available,
                            color: s.critical == true ? Colors.red : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.maintenanceType ?? 'ТО'} • ${_formatDate(s.scheduledDate) ?? 'дата не указана'}',
                              style: const TextStyle(color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJournalTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Дорожка'),
                  keyboardType: TextInputType.number,
                  onSubmitted: _updateLaneFilter,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                hint: const Text('Тип'),
                value: _workTypeFilter,
                items: const [
                  '',
                  'PREVENTIVE_MAINTENANCE',
                  'CORRECTIVE_MAINTENANCE',
                  'EMERGENCY_REPAIR',
                  'INSTALLATION',
                  'REPLACEMENT',
                  'INSPECTION',
                  'CLEANING',
                  'CALIBRATION',
                  'UPGRADE',
                  'OTHER',
                ]
                    .map((e) => DropdownMenuItem(value: e.isEmpty ? null : e, child: Text(e.isEmpty ? 'Все типы' : e)))
                    .toList(),
                onChanged: _updateWorkType,
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                hint: const Text('Статус'),
                value: _statusFilter,
                items: const [
                  '',
                  'CREATED',
                  'ASSIGNED',
                  'IN_PROGRESS',
                  'ON_HOLD',
                  'COMPLETED',
                  'VERIFIED',
                  'CLOSED',
                  'CANCELLED',
                ]
                    .map((e) => DropdownMenuItem(value: e.isEmpty ? null : e, child: Text(e.isEmpty ? 'Все' : e)))
                    .toList(),
                onChanged: _updateStatus,
              ),
              IconButton(onPressed: _pickDates, icon: const Icon(Icons.date_range)),
            ],
          ),
        ),
        Expanded(
          child: _journal.isEmpty
              ? const Center(child: Text('Нет записей журнала', style: TextStyle(color: AppColors.darkGray)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _journal.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final entry = _journal[i];
                      return CommonUI.card(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.requestId != null ? 'Заявка ${entry.requestId}' : 'Работа ${entry.serviceHistoryId ?? '-'}'} • дорожка ${entry.laneNumber ?? '-'}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                                  ),
                                ),
                                Chip(
                                  label: Text(entry.status ?? entry.requestStatus ?? ''),
                                  backgroundColor: AppColors.background,
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.workType ?? entry.serviceType ?? 'Тип работы не указан',
                              style: const TextStyle(color: AppColors.darkGray),
                            ),
                            const SizedBox(height: 6),
                            _infoRow('Оборудование', entry.equipmentModel ?? '—'),
                            _infoRow('Исполнитель', entry.mechanicName ?? '—'),
                            _infoRow('Создано', _formatDateTime(entry.createdDate) ?? '—'),
                            _infoRow('Работа выполнена',
                                _formatDateTime(entry.completedDate ?? entry.serviceDate) ?? '—'),
                            if (entry.partsUsed.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Использованные детали', style: TextStyle(fontWeight: FontWeight.w600)),
                              ...entry.partsUsed.map((p) => Text('- ${p.partName} (${p.quantityUsed} шт.)')),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ),
        )
      ],
    );
  }

  Widget _buildWarningsTab() {
    if (_warnings.isEmpty) {
      return const Center(
        child: Text('Активных предупреждений нет', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _warnings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final warning = _warnings[i];
          final isCritical =
              warning.type.contains('OVERDUE') || warning.type.contains('EXCEEDED') || warning.type.contains('CRITICAL');
          return Container(
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.withOpacity(0.08) : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCritical ? Colors.red : AppColors.lightGray),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isCritical ? Icons.error_outline : Icons.info_outline,
                        color: isCritical ? Colors.red : AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(warning.message, style: const TextStyle(color: AppColors.textDark)),
                    ),
                  ],
                ),
                if (warning.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Срок: ${_formatDate(warning.dueDate)}',
                        style: const TextStyle(color: AppColors.darkGray)),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Text('Оповещения отсутствуют', style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final notif = _notifications[i];
          final isHelp = notif.isHelpEvent;
          final isWarning = notif.isWarningEvent;
          final isComplaint = notif.isSupplierComplaint;
          final isAccess = notif.isAccessRequest;
          final label = notif.typeKey.label();
          final status = deriveHelpRequestStatus(events: _notifications, requestId: notif.requestId ?? -1);
          final Color accentColor = isWarning
              ? Colors.orange
              : isComplaint
                  ? Colors.deepPurple
                  : isAccess
                      ? Colors.blueGrey
                      : AppColors.primary;
          return CommonUI.card(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: TextStyle(fontWeight: FontWeight.w700, color: accentColor)),
                    ),
                    if (isHelp)
                      Chip(
                        label: Text(_helpStatusLabel(status.resolution),
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: _helpStatusColor(status.resolution),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notif.message, style: const TextStyle(color: AppColors.darkGray)),
                if (notif.payload != null && notif.payload!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(notif.payload!, style: const TextStyle(color: AppColors.darkGray)),
                  ),
                if (notif.partIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Позиции: ${notif.partIds.join(', ')}',
                        style: const TextStyle(color: AppColors.darkGray)),
                  ),
                if (notif.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDateTime(notif.createdAt!) ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                    ),
                  ),
                if (isHelp && notif.requestId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openRequest(notif.requestId!),
                            icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                            label: const Text('Открыть заявку'),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRequest(int requestId) async {
    try {
      final detail = await _maintenanceRepository.getById(requestId);
      if (detail == null) {
        showSnack(context, 'Не удалось открыть заявку $requestId');
        return;
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSummaryScreen(
            orderNumber: 'Заявка №${detail.requestId}',
            order: detail,
            canResolveHelp: true,
            canRequestHelp: false,
            canConfirm: false,
            canComplete: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Color _helpStatusColor(HelpRequestResolution resolution) {
    switch (resolution) {
      case HelpRequestResolution.approved:
        return Colors.green;
      case HelpRequestResolution.declined:
        return Colors.redAccent;
      case HelpRequestResolution.reassigned:
        return Colors.blue;
      case HelpRequestResolution.awaiting:
        return Colors.orange;
      case HelpRequestResolution.none:
      default:
        return AppColors.darkGray;
    }
  }

  String _helpStatusLabel(HelpRequestResolution resolution) {
    switch (resolution) {
      case HelpRequestResolution.approved:
        return 'Подтверждено';
      case HelpRequestResolution.declined:
        return 'Отклонено';
      case HelpRequestResolution.reassigned:
        return 'Переназначено';
      case HelpRequestResolution.awaiting:
        return 'Ожидание';
      case HelpRequestResolution.none:
      default:
        return 'Без статуса';
    }
  }

  String? _formatDate(DateTime? date) => date != null ? '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' : null;

  String? _formatDateTime(DateTime? date) {
    if (date == null) return null;
    final d = _formatDate(date);
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$d $time';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: AppColors.darkGray))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textDark))),
        ],
      ),
    );
  }
}
