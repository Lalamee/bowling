import 'package:flutter/material.dart';

import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/owner_dashboard_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/notifications_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/services/authz/acl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/utils/help_request_status_helper.dart';
import '../../../../models/notification_event_dto.dart';
import '../../../../models/club_appeal_request_dto.dart';
import '../../../../models/service_journal_entry_dto.dart';
import '../../../../models/technical_info_create_dto.dart';
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

  static const Map<String, String> _statusLabels = {
    'CREATED': 'Создано',
    'ASSIGNED': 'Назначено',
    'IN_PROGRESS': 'В работе',
    'ON_HOLD': 'На паузе',
    'COMPLETED': 'Завершено',
    'VERIFIED': 'Проверено',
    'CLOSED': 'Закрыто',
    'CANCELLED': 'Отменено',
  };

  static const Map<String, String> _workTypeLabels = {
    'PREVENTIVE_MAINTENANCE': 'Профилактическое обслуживание',
    'CORRECTIVE_MAINTENANCE': 'Корректирующее обслуживание',
    'EMERGENCY_REPAIR': 'Аварийный ремонт',
    'INSTALLATION': 'Установка',
    'REPLACEMENT': 'Замена',
    'INSPECTION': 'Инспекция',
    'CLEANING': 'Чистка',
    'CALIBRATION': 'Калибровка',
    'UPGRADE': 'Апгрейд',
    'OTHER': 'Другое',
  };

  bool _isLoading = true;
  bool _hasError = false;
  List<UserClub> _clubs = const [];
  int? _selectedClubId;
  String? _roleName;
  UserAccessScope? _accessScope;

  static const List<String> _equipmentOptions = ['AMF', 'Brunswick', 'VIA', 'XIMA', 'Другое'];
  static const Map<String, List<String>> _equipmentModels = {
    'AMF': ['82/70XLi', '82/90XLi', 'HVO'],
    'Brunswick': ['A2', 'GS-X', 'GS-X Lite', 'NXT'],
    'VIA': ['VIA Vector', 'VIA Edge'],
    'XIMA': ['XIMA Phoenix', 'XIMA Evo'],
  };

  List<TechnicalInfoDto> _technical = const [];
  List<ServiceJournalEntryDto> _journal = const [];
  List<WarningDto> _warnings = const [];
  List<NotificationEventDto> _notifications = const [];

  int? _laneFilter;
  String? _workTypeFilter;
  String? _statusFilter;
  DateTimeRange? _dateRange;
  bool _criticalWarningsOnly = false;
  NotificationEventType? _notificationFilter;

  final _laneController = TextEditingController();
  final _appealMessageController = TextEditingController();
  final _appealRequestController = TextEditingController();

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
    _laneController.dispose();
    _appealMessageController.dispose();
    _appealRequestController.dispose();
    super.dispose();
  }

  static const Map<NotificationEventType, String> _appealTypeLabels = {
    NotificationEventType.clubTechSupport: 'Техническая помощь / сервис',
    NotificationEventType.clubSupplierRefusal: 'Отказ поставщика',
    NotificationEventType.clubMechanicFailure: 'Невозможность ремонта',
    NotificationEventType.clubLegalAssistance: 'Юридическая помощь',
    NotificationEventType.clubSpecialistAccess: 'Доступ к базе специалистов',
  };

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      final clubs = resolveUserClubs(me);
      final role = me['role']?.toString() ?? me['roleName']?.toString();
      int? selectedId;
      if (widget.initialClubId != null && clubs.any((c) => c.id == widget.initialClubId)) {
        selectedId = widget.initialClubId;
      } else if (clubs.isNotEmpty) {
        selectedId = clubs.first.id;
      }
      setState(() {
        _clubs = clubs;
        _selectedClubId = selectedId;
        _roleName = role;
        _accessScope = scope;
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
        _notificationsRepository.fetchNotifications(clubId: _selectedClubId, role: _roleName),
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

  bool get _canEditTechnicalInfo {
    final role = _accessScope?.role;
    return role == 'admin' || role == 'owner' || role == 'manager';
  }

  void _toggleCriticalWarnings(bool? value) {
    setState(() => _criticalWarningsOnly = value ?? false);
  }

  void _updateNotificationFilter(NotificationEventType? filter) {
    setState(() => _notificationFilter = filter);
  }

  String _appealTypeToApi(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.clubTechSupport:
        return 'CLUB_TECH_SUPPORT';
      case NotificationEventType.clubSupplierRefusal:
        return 'CLUB_SUPPLIER_REFUSAL';
      case NotificationEventType.clubMechanicFailure:
        return 'CLUB_MECHANIC_FAILURE';
      case NotificationEventType.clubLegalAssistance:
        return 'CLUB_LEGAL_ASSISTANCE';
      case NotificationEventType.clubSpecialistAccess:
        return 'CLUB_SPECIALIST_ACCESS';
      default:
        return type.name.toUpperCase();
    }
  }

  Future<void> _openAppealSheet() async {
    if (_selectedClubId == null) {
      showApiError(context, 'Выберите клуб для отправки обращения');
      return;
    }
    NotificationEventType selectedType = NotificationEventType.clubTechSupport;
    _appealMessageController.clear();
    _appealRequestController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Обращение в администрацию',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NotificationEventType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Тип обращения'),
                    items: _appealTypeLabels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _appealMessageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Сообщение',
                      hintText: 'Опишите проблему или запрос',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _appealRequestController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Номер заявки (если есть)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final message = _appealMessageController.text.trim();
                        if (message.isEmpty) {
                          showApiError(context, 'Заполните сообщение обращения');
                          return;
                        }
                        final requestId = int.tryParse(_appealRequestController.text.trim());
                        try {
                          await _repository.submitClubAppeal(
                            ClubAppealRequestDto(
                              clubId: _selectedClubId,
                              type: _appealTypeToApi(selectedType),
                              message: message,
                              requestId: requestId,
                            ),
                          );
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Обращение отправлено')),
                          );
                          await _loadData();
                        } catch (e) {
                          if (!mounted) return;
                          showApiError(context, e);
                        }
                      },
                      child: const Text('Отправить'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _clearLaneFilter() {
    _laneController.clear();
    _laneFilter = null;
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Нет данных по оборудованию', style: TextStyle(color: AppColors.darkGray)),
              if (_canEditTechnicalInfo) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openCreateTechnicalInfoSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить техническую информацию'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _technical.length + (_canEditTechnicalInfo ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (_canEditTechnicalInfo && i == 0) {
            return FilledButton.icon(
              onPressed: _openCreateTechnicalInfoSheet,
              icon: const Icon(Icons.add),
              label: const Text('Добавить техническую информацию'),
            );
          }
          final offset = _canEditTechnicalInfo ? 1 : 0;
          final item = _technical[i - offset];
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
                _infoRow('Дорожек', item.lanesCount?.toString() ?? '—'),
                _infoRow('Производитель', item.manufacturer ?? '—'),
                _infoRow('Год выпуска', item.productionYear?.toString() ?? '—'),
                _infoRow('Серийный номер', item.serialNumber ?? '—'),
                _infoRow('Статус', item.status ?? '—'),
                _infoRow(
                    'Плановое ТО',
                    _formatDate(item.nextMaintenanceDate) ??
                        (item.nextMaintenanceDate == null ? 'Не запланировано' : '—')),
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
                      ...item.components.map(
                        (c) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.category != null) Text('Категория: ${c.category}'),
                              if (c.manufacturer != null) Text('Производитель: ${c.manufacturer}'),
                              if (c.code != null) Text('Код: ${c.code}'),
                              if (c.notes != null) Text('Описание: ${c.notes}'),
                            ],
                          ),
                        ),
                      )
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
                            color: s.critical == true
                                ? Colors.red
                                : (s.scheduledDate != null && s.scheduledDate!.isBefore(DateTime.now())
                                    ? Colors.orange
                                    : AppColors.primary),
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

  Future<void> _openCreateTechnicalInfoSheet() async {
    final clubId = _selectedClubId;
    if (clubId == null) {
      showSnack(context, 'Выберите клуб');
      return;
    }
    final club = _clubs.firstWhere((c) => c.id == clubId, orElse: () => _clubs.first);
    final equipmentName = club.equipment;

    final modelController = TextEditingController();
    final customManufacturerController = TextEditingController();
    final serialController = TextEditingController();
    final lanesController = TextEditingController(text: club.lanes ?? '');
    final yearController = TextEditingController();
    final conditionController = TextEditingController();
    String? selectedEquipment = _equipmentOptions.contains(equipmentName) ? equipmentName : null;
    String? selectedModel;
    bool submitting = false;
    final formKey = GlobalKey<FormState>();
    DateTime? purchaseDate;
    DateTime? warrantyUntil;
    DateTime? lastMaintenanceDate;
    DateTime? nextMaintenanceDate;

    Future<void> pickDate(ValueChanged<DateTime?> onPicked, DateTime? current) async {
      final now = DateTime.now();
      final initial = current ?? now;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(now.year - 20),
        lastDate: DateTime(now.year + 20),
      );
      onPicked(picked);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() => submitting = true);
              try {
                final manufacturer = selectedEquipment == 'Другое'
                    ? customManufacturerController.text.trim()
                    : selectedEquipment;
                final model = selectedEquipment == 'Другое'
                    ? modelController.text.trim()
                    : (selectedModel ?? modelController.text.trim());
                final dto = TechnicalInfoCreateDto(
                  clubId: clubId,
                  manufacturer: manufacturer,
                  equipmentType: manufacturer,
                  model: model,
                  serialNumber: serialController.text.trim().isEmpty ? null : serialController.text.trim(),
                  lanesCount: int.tryParse(lanesController.text.trim()),
                  productionYear: int.tryParse(yearController.text.trim()),
                  conditionPercentage: int.tryParse(conditionController.text.trim()),
                  purchaseDate: purchaseDate,
                  warrantyUntil: warrantyUntil,
                  lastMaintenanceDate: lastMaintenanceDate,
                  nextMaintenanceDate: nextMaintenanceDate,
                );
                await _repository.createTechnicalInfo(dto);
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Техническая информация добавлена')),
                );
              } catch (e) {
                if (!mounted) return;
                showApiError(context, e);
              } finally {
                if (mounted) {
                  setModalState(() => submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавить техническую информацию',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedEquipment,
                      decoration: const InputDecoration(labelText: 'Производитель'),
                      items: _equipmentOptions
                          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                          .toList(),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Выберите производителя' : null,
                      onChanged: submitting
                          ? null
                          : (value) => setModalState(() {
                                selectedEquipment = value;
                                selectedModel = null;
                                modelController.clear();
                                customManufacturerController.clear();
                              }),
                    ),
                    if (selectedEquipment != null && selectedEquipment != 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<String>(
                          value: selectedModel,
                          decoration: const InputDecoration(labelText: 'Модель оборудования'),
                          items: (_equipmentModels[selectedEquipment] ?? const [])
                              .map((model) => DropdownMenuItem(value: model, child: Text(model)))
                              .toList(),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Выберите модель оборудования' : null,
                          onChanged: submitting ? null : (value) => setModalState(() => selectedModel = value),
                        ),
                      ),
                    if (selectedEquipment == 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: customManufacturerController,
                          decoration: const InputDecoration(labelText: 'Производитель (другое)'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Укажите производителя' : null,
                          enabled: !submitting,
                        ),
                      ),
                    if (selectedEquipment == 'Другое')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: modelController,
                          decoration: const InputDecoration(labelText: 'Модель оборудования'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Укажите модель оборудования' : null,
                          enabled: !submitting,
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: serialController,
                      decoration: const InputDecoration(labelText: 'Серийный номер'),
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lanesController,
                      decoration: const InputDecoration(labelText: 'Количество дорожек'),
                      keyboardType: TextInputType.number,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: yearController,
                      decoration: const InputDecoration(labelText: 'Год выпуска'),
                      keyboardType: TextInputType.number,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: conditionController,
                      decoration: const InputDecoration(labelText: 'Состояние, %'),
                      keyboardType: TextInputType.number,
                      enabled: !submitting,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Дата покупки',
                        hintText: purchaseDate != null ? _formatDate(purchaseDate!) : 'Не указано',
                      ),
                      onTap: submitting ? null : () => pickDate((picked) => setModalState(() => purchaseDate = picked), purchaseDate),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Гарантия до',
                        hintText: warrantyUntil != null ? _formatDate(warrantyUntil!) : 'Не указано',
                      ),
                      onTap: submitting ? null : () => pickDate((picked) => setModalState(() => warrantyUntil = picked), warrantyUntil),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Последнее ТО',
                        hintText: lastMaintenanceDate != null ? _formatDate(lastMaintenanceDate!) : 'Не указано',
                      ),
                      onTap: submitting ? null : () => pickDate((picked) => setModalState(() => lastMaintenanceDate = picked), lastMaintenanceDate),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Следующее ТО',
                        hintText: nextMaintenanceDate != null ? _formatDate(nextMaintenanceDate!) : 'Не указано',
                      ),
                      onTap: submitting ? null : () => pickDate((picked) => setModalState(() => nextMaintenanceDate = picked), nextMaintenanceDate),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJournalTab() {
    _laneController.text = _laneFilter?.toString() ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: _laneController,
                  decoration: InputDecoration(
                    labelText: 'Дорожка',
                    suffixIcon: _laneFilter != null
                        ? IconButton(
                            onPressed: _clearLaneFilter,
                            icon: const Icon(Icons.clear, size: 18),
                          )
                        : null,
                  ),
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
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.isEmpty ? null : e,
                        child: Text(_workTypeLabel(e, allowAllLabel: true)),
                      ),
                    )
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
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.isEmpty ? null : e,
                        child: Text(e.isEmpty ? 'Все' : _statusLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: _updateStatus,
              ),
              IconButton(onPressed: _pickDates, icon: const Icon(Icons.date_range)),
            ],
          ),
        ),
        if (_laneFilter != null || _workTypeFilter != null || _statusFilter != null || _dateRange != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_laneFilter != null)
                  Chip(
                    label: Text('Дорожка $_laneFilter'),
                    onDeleted: _clearLaneFilter,
                  ),
                if (_workTypeFilter != null)
                  Chip(
                    label: Text('Тип: ${_workTypeLabel(_workTypeFilter, allowAllLabel: true)}'),
                    onDeleted: () => _updateWorkType(null),
                  ),
                if (_statusFilter != null)
                  Chip(
                    label: Text('Статус: ${_statusLabel(_statusFilter)}'),
                    onDeleted: () => _updateStatus(null),
                  ),
                if (_dateRange != null)
                  Chip(
                    label: Text(
                        'Период: ${_formatDate(_dateRange?.start)}–${_formatDate(_dateRange?.end)}'),
                    onDeleted: () {
                      setState(() => _dateRange = null);
                      _loadData();
                    },
                  ),
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
                                label: Text(_statusLabel(entry.status ?? entry.requestStatus)),
                                backgroundColor: AppColors.background,
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final primaryWorkType = _workTypeLabel(entry.workType);
                            final secondaryWorkType = _workTypeLabel(entry.serviceType);
                            final workTypeText = primaryWorkType != 'Не указан'
                                ? primaryWorkType
                                : secondaryWorkType != 'Не указан'
                                    ? secondaryWorkType
                                    : entry.workType ??
                                        entry.serviceType ??
                                        'Тип работы не указан';
                            return Text(
                              workTypeText,
                              style: const TextStyle(color: AppColors.darkGray),
                            );
                          }),
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
    final filtered = _criticalWarningsOnly
        ? _warnings.where((w) => w.isCritical).toList()
        : _warnings;
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text('Активных предупреждений нет', style: TextStyle(color: AppColors.darkGray)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Row(
              children: [
                Checkbox(value: _criticalWarningsOnly, onChanged: _toggleCriticalWarnings),
                const Text('Только критичные/просроченные'),
              ],
            );
          }
          final warning = filtered[i - 1];
          final isCritical = warning.isCritical;
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
                    Chip(
                      label: Text(warning.type),
                      backgroundColor: AppColors.background,
                    )
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
    final filtered = _notificationFilter == null
        ? _notifications
        : _notifications.where((n) => n.typeKey == _notificationFilter).toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.isEmpty ? 3 : filtered.length + 2,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return CommonUI.card(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Обращение в администрацию',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Отправьте запрос по технической помощи, отказу поставщика или юридической поддержке.',
                    style: TextStyle(color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openAppealSheet,
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Создать обращение'),
                    ),
                  ),
                ],
              ),
            );
          }
          if (i == 1) {
            return Row(
              children: [
                const Text('Фильтр:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<NotificationEventType?>(
                  value: _notificationFilter,
                  hint: const Text('Все события'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все события')),
                    ...NotificationEventType.values
                        .where((e) => e != NotificationEventType.unknown)
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.label()),
                          ),
                        )
                  ],
                  onChanged: _updateNotificationFilter,
                )
              ],
            );
          }
          if (filtered.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Нет событий для выбранного фильтра',
                  style: TextStyle(color: AppColors.darkGray)),
            );
          }
          final notif = filtered[i - 2];
          final isHelp = notif.isHelpEvent;
          final isWarning = notif.isWarningEvent;
          final isComplaint = notif.isSupplierComplaint;
          final isAccess = notif.isAccessRequest;
          final isStaff = notif.isStaffAccess;
          final isTechSupport = notif.isTechSupport;
          final isAdminReply = notif.isAdminReply;
          final label = notif.typeKey.label();
          final status = deriveHelpRequestStatus(events: _notifications, requestId: notif.requestId ?? -1);
          final Color accentColor = isWarning
              ? Colors.orange
              : isComplaint
                  ? Colors.deepPurple
                  : isAccess || isStaff
                      ? Colors.blueGrey
                      : isTechSupport
                          ? Colors.teal
                          : isAdminReply
                              ? Colors.indigo
                              : AppColors.primary;
          return CommonUI.card(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isWarning
                          ? Icons.warning_amber
                          : isComplaint
                              ? Icons.rule_folder
                              : isStaff
                                  ? Icons.manage_accounts
                                  : isTechSupport
                                      ? Icons.build
                                      : isAdminReply
                                          ? Icons.mark_email_read
                                          : Icons.notifications,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: accentColor))),
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

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Без статуса';
    final normalized = status.toUpperCase();
    return _statusLabels[normalized] ?? status;
  }

  String _workTypeLabel(String? workType, {bool allowAllLabel = false}) {
    if (workType == null || workType.isEmpty) {
      return allowAllLabel ? 'Все типы' : 'Не указан';
    }
    final normalized = workType.toUpperCase();
    return _workTypeLabels[normalized] ?? workType;
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
