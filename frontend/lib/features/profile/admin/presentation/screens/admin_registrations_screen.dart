import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/repositories/admin_cabinet_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/authz/role_access.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/admin_account_update_dto.dart';
import '../../../../../models/admin_mechanic_account_change_dto.dart';
import '../../../../../models/admin_registration_application_dto.dart';
import '../../../../../models/mechanic_club_link_request_dto.dart';
import '../../../../../models/club_summary_dto.dart';

class AdminRegistrationsScreen extends StatefulWidget {
  const AdminRegistrationsScreen({super.key});

  @override
  State<AdminRegistrationsScreen> createState() => _AdminRegistrationsScreenState();
}

class _AdminRegistrationsScreenState extends State<AdminRegistrationsScreen> {
  final AdminCabinetRepository _repository = AdminCabinetRepository();
  final ClubsRepository _clubsRepository = ClubsRepository();

  bool _loading = true;
  bool _error = false;
  List<AdminRegistrationApplicationDto> _applications = [];
  List<ClubSummaryDto> _clubs = [];
  String? _roleFilter;
  String? _accountFilter;
  String? _statusFilter;
  String? _typeFilter;
  _SortField _sortField = _SortField.status;
  bool _sortAsc = true;
  DateTime? _from;
  DateTime? _to;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _roleLabels = {
    'ADMIN': 'Администрация',
    'MECHANIC': 'Механик',
    'HEAD_MECHANIC': 'Менеджер',
    'CLUB_OWNER': 'Владелец клуба',
  };

  static const Map<String, String> _accountLabels = {
    'INDIVIDUAL': 'Механик',
    'CLUB_OWNER': 'Владелец',
    'CLUB_MANAGER': 'Менеджер клуба',
    'FREE_MECHANIC_BASIC': 'Свободный механик (базовый)',
    'FREE_MECHANIC_PREMIUM': 'Свободный механик (премиум)',
    'MAIN_ADMIN': 'Администрация сервиса',
  };

  static const Map<String, String> _statusLabels = {
    'PENDING': 'В обработке',
    'APPROVED': 'Одобрена',
    'REJECTED': 'Отклонена',
    'DRAFT': 'Черновик',
  };

  static const Map<String, String> _applicationTypeLabels = {
    'MECHANIC': 'Механик',
    'CLUB': 'Клуб',
    'MANAGER': 'Менеджер клуба',
    'OWNER': 'Владелец клуба',
    'ADMIN': 'Администратор',
  };

  static const Map<String, int> _statusOrder = {
    'PENDING': 0,
    'DRAFT': 1,
    'APPROVED': 2,
    'REJECTED': 3,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final appsFuture = _repository.getRegistrations();
      final clubsFuture = _clubsRepository.getClubs();
      final apps = await appsFuture;
      final clubs = await clubsFuture;
      if (!mounted) return;
      setState(() {
        _applications = apps.where((app) => app.isVerified != true).toList();
        _clubs = clubs;
        _loading = false;
      });
    } catch (e, s) {
      log('Failed to load registrations: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      showApiError(context, e);
    }
  }

  List<AdminRegistrationApplicationDto> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _applications.where((app) {
      final matchesRole = _roleFilter == null || app.role?.toLowerCase() == _roleFilter?.toLowerCase();
      final matchesAcc = _accountFilter == null || app.accountType?.toLowerCase() == _accountFilter?.toLowerCase();
      final matchesStatus = _statusFilter == null || app.status?.toLowerCase() == _statusFilter?.toLowerCase();
      final matchesType = _typeFilter == null || app.applicationType?.toLowerCase() == _typeFilter?.toLowerCase();
      final submitted = app.submittedAt;
      final matchesFrom = _from == null || (submitted != null && !submitted.isBefore(_from!));
      final matchesTo = _to == null || (submitted != null && !submitted.isAfter(_to!));
      final matchesQuery = query.isEmpty ||
          (app.fullName?.toLowerCase().contains(query) ?? false) ||
          (app.phone?.toLowerCase().contains(query) ?? false) ||
          (app.clubName?.toLowerCase().contains(query) ?? false);
      return matchesRole && matchesAcc && matchesStatus && matchesType && matchesFrom && matchesTo && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortField) {
        case _SortField.type:
          return _compareNullableStrings(_applicationTypeLabel(a.applicationType), _applicationTypeLabel(b.applicationType));
        case _SortField.status:
          final orderA = _statusOrder[_resolveStatus(a).toUpperCase()] ?? 999;
          final orderB = _statusOrder[_resolveStatus(b).toUpperCase()] ?? 999;
          return orderA.compareTo(orderB);
        case _SortField.date:
          final aDate = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
      }
    });

    if (!_sortAsc) {
      return filtered.reversed.toList();
    }
    return filtered;
  }

  Future<void> _approve(AdminRegistrationApplicationDto app) async {
    if (app.userId == null) return;
    if (app.role == 'MECHANIC') {
      final prepared = await _prepareMechanicAccount(app);
      if (prepared != null) {
        app = prepared;
      } else {
        return;
      }
    }
    try {
      final updated = await _repository.approveRegistration(app.userId!);
      if (!mounted) return;
      _replace(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка одобрена')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _reject(AdminRegistrationApplicationDto app) async {
    if (app.userId == null) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить заявку'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Причина'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Отклонить')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final updated = await _repository.rejectRegistration(app.userId!, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      _replace(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка отклонена')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  void _replace(AdminRegistrationApplicationDto updated) {
    setState(() {
      _applications = _applications.map((e) => e.userId == updated.userId ? updated : e).toList();
    });
  }

  Future<void> _updateAccount(AdminRegistrationApplicationDto app) async {
    if (app.userId == null) return;
    final decision = await _askAccountChange(app.accountType, allowClub: true, initialClubId: app.clubId);
    if (decision == null) return;
    try {
      final updated = await _repository.convertMechanicAccount(
        app.userId!,
        decision,
      );
      if (!mounted) return;
      _replace(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аккаунт обновлён')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _changeClub(AdminRegistrationApplicationDto app, {required bool attach}) async {
    if (app.profileId == null) return;
    int? selectedClub = app.clubId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(attach ? 'Назначить клуб' : 'Убрать из клуба'),
        content: attach
            ? DropdownButtonFormField<int?>(
                value: selectedClub,
                decoration: const InputDecoration(labelText: 'Клуб'),
                items: _clubs
                    .map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name ?? 'Клуб ${c.id}'),
                        ))
                    .toList(),
                onChanged: (value) => selectedClub = value,
                validator: (value) => value == null ? 'Выберите клуб' : null,
              )
            : const Text('Подтвердите отвязку механика от клуба'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final updated = await _repository.changeMechanicClubLink(
        app.profileId!,
        MechanicClubLinkRequestDto(clubId: selectedClub, attach: attach),
      );
      if (!mounted) return;
      _replace(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Привязка обновлена')));
    } catch (e) {
      if (!mounted) return;
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
        title: const Text('Заявки на регистрацию'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: AppColors.primary))],
      ),
      body: _buildBody(),
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
            const Text('Не удалось загрузить заявки'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Фильтры'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_from == null ? 'С' : 'С: ${_from!.toLocal().toString().split(' ').first}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_to == null ? 'По' : 'По: ${_to!.toLocal().toString().split(' ').first}'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemBuilder: (_, i) => _buildCard(items[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AdminRegistrationApplicationDto app) {
    final status = _resolveStatus(app);
    final role = app.role ?? '—';
    final account = app.accountType ?? '—';
    final type = app.applicationType ?? role;
    final statusLabel = _statusLabel(status);
    final roleLabel = _roleLabel(role);
    final accountLabel = _accountLabel(account);
    final typeLabel = _applicationTypeLabel(type);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName ?? 'Без имени', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(app.phone ?? '—'),
                    ],
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Тип: $typeLabel • Роль: $roleLabel • Аккаунт: $accountLabel'),
            if (app.clubName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Клуб: ${app.clubName}'),
              ),
            if (app.submittedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Отправлено: ${_formatDate(app.submittedAt!)}'),
              ),
            if (app.decisionComment != null && app.decisionComment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Комментарий: ${app.decisionComment}'),
              ),
            if (app.payload != null && app.payload!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: app.payload!.entries
                      .map(
                        (e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _approve(app),
                  icon: const Icon(Icons.check),
                  label: const Text('Одобрить'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reject(app),
                  icon: const Icon(Icons.close),
                  label: const Text('Отклонить'),
                ),
                if (app.role == 'MECHANIC')
                  OutlinedButton.icon(
                    onPressed: () => _updateAccount(app),
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Аккаунт'),
                  ),
                if (app.role == 'MECHANIC' && (app.profileId != null))
                  OutlinedButton.icon(
                    onPressed: () => _changeClub(app, attach: true),
                    icon: const Icon(Icons.add_business),
                    label: const Text('Назначить клуб'),
                  ),
                if (app.role == 'MECHANIC' && app.clubId != null)
                  OutlinedButton.icon(
                    onPressed: () => _changeClub(app, attach: false),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Убрать из клуба'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveStatus(AdminRegistrationApplicationDto app) {
    if (app.status != null) return app.status!;
    if (app.isVerified == true) return 'APPROVED';
    if (app.isActive == false || app.isVerified == false) return 'PENDING';
    return 'DRAFT';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now.subtract(const Duration(days: 7))) : (_to ?? now);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        if (isFrom) {
          _from = selected;
        } else {
          _to = selected;
        }
      });
    }
  }

  Future<AdminMechanicAccountChangeDto?> _askAccountChange(String? currentAccount, {bool allowClub = false, int? initialClubId}) async {
    String? account = currentAccount;
    String? access = 'PREMIUM';
    bool attachToClub = allowClub && initialClubId != null;
    int? selectedClub = initialClubId;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройка аккаунта механика'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: account,
                decoration: const InputDecoration(labelText: 'Тип аккаунта'),
                items: AccountTypeName.values
                    .map((t) => DropdownMenuItem<String?>(
                          value: t.apiName,
                          child: Text(t.apiName),
                        ))
                    .toList(),
                onChanged: (value) => account = value,
                validator: (value) => (value == null || value.isEmpty) ? 'Выберите тип аккаунта' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: access,
                decoration: const InputDecoration(labelText: 'Уровень доступа'),
                items: const [
                  DropdownMenuItem(value: 'PREMIUM', child: Text('PREMIUM')),
                  DropdownMenuItem(value: 'BASIC', child: Text('BASIC')),
                ],
                onChanged: (value) => access = value,
                validator: (value) => (value == null || value.isEmpty) ? 'Укажите уровень доступа' : null,
              ),
              if (allowClub) ...[
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: attachToClub,
                  title: const Text('Привязать к клубу'),
                  onChanged: (v) => attachToClub = v,
                ),
                DropdownButtonFormField<int?>(
                  value: selectedClub,
                  decoration: const InputDecoration(labelText: 'Клуб'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Без клуба')),
                    ..._clubs
                        .map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name ?? 'Клуб ${c.id}'),
                            ))
                        .toList(),
                  ],
                  onChanged: attachToClub ? (value) => selectedClub = value : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;
    return AdminMechanicAccountChangeDto(
      accountTypeName: account,
      accessLevelName: access,
      clubId: attachToClub ? selectedClub : null,
      attachToClub: attachToClub,
    );
  }

  Future<void> _openFilterSheet() async {
    String? role = _roleFilter;
    String? account = _accountFilter;
    String? status = _statusFilter;
    String? type = _typeFilter;
    var sortField = _sortField;
    var sortAsc = _sortAsc;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Фильтры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  label: 'Роль',
                  value: role,
                  options: _roleLabels,
                  onChanged: (v) => role = v,
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  label: 'Тип аккаунта',
                  value: account,
                  options: _accountLabels,
                  onChanged: (v) => account = v,
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  label: 'Статус',
                  value: status,
                  options: _statusLabels,
                  onChanged: (v) => status = v,
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  label: 'Тип заявки',
                  value: type,
                  options: _applicationTypeLabels,
                  onChanged: (v) => type = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_SortField>(
                  value: sortField,
                  decoration: const InputDecoration(labelText: 'Сортировка'),
                  items: const [
                    DropdownMenuItem(value: _SortField.status, child: Text('По статусу')),
                    DropdownMenuItem(value: _SortField.type, child: Text('По типу заявки')),
                    DropdownMenuItem(value: _SortField.date, child: Text('По дате подачи')),
                  ],
                  onChanged: (v) => sortField = v ?? sortField,
                ),
                SwitchListTile.adaptive(
                  value: sortAsc,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('По возрастанию'),
                  onChanged: (v) => sortAsc = v,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _roleFilter = null;
                            _accountFilter = null;
                            _statusFilter = null;
                            _typeFilter = null;
                            _sortField = _SortField.status;
                            _sortAsc = true;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Сбросить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _roleFilter = role;
                            _accountFilter = account;
                            _statusFilter = status;
                            _typeFilter = type;
                            _sortField = sortField;
                            _sortAsc = sortAsc;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Применить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все')),
        ...options.entries
            .map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value)))
            .toList(),
      ],
      onChanged: onChanged,
    );
  }

  String _roleLabel(String? role) {
    if (role == null) return '—';
    final key = role.trim().toUpperCase();
    return _roleLabels[key] ?? role;
  }

  String _accountLabel(String? account) {
    if (account == null) return '—';
    final key = account.trim().toUpperCase();
    return _accountLabels[key] ?? account;
  }

  String _statusLabel(String? status) {
    if (status == null) return '—';
    final key = status.trim().toUpperCase();
    return _statusLabels[key] ?? status;
  }

  String _applicationTypeLabel(String? type) {
    if (type == null) return '—';
    final key = type.trim().toUpperCase();
    return _applicationTypeLabels[key] ?? type;
  }

  Future<AdminRegistrationApplicationDto?> _prepareMechanicAccount(AdminRegistrationApplicationDto app) async {
    final decision = await _askAccountChange(app.accountType, allowClub: true, initialClubId: app.clubId);
    if (decision == null || app.userId == null) return null;
    final updated = await _repository.convertMechanicAccount(app.userId!, decision);
    _replace(updated);
    return updated;
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date.toLocal());

  int _compareNullableStrings(String? a, String? b) {
    final left = (a ?? '').toLowerCase();
    final right = (b ?? '').toLowerCase();
    return left.compareTo(right);
  }
}

enum _SortField { status, type, date }
