import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/admin_cabinet_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/admin_account_update_dto.dart';
import '../../../../../models/admin_registration_application_dto.dart';
import '../../../../../models/mechanic_club_link_request_dto.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../core/authz/role_access.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();

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
        _applications = apps;
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
    return _applications.where((app) {
      final matchesRole = _roleFilter == null || app.role?.toLowerCase() == _roleFilter?.toLowerCase();
      final matchesAcc = _accountFilter == null || app.accountType?.toLowerCase() == _accountFilter?.toLowerCase();
      final matchesQuery = query.isEmpty ||
          (app.fullName?.toLowerCase().contains(query) ?? false) ||
          (app.phone?.toLowerCase().contains(query) ?? false) ||
          (app.clubName?.toLowerCase().contains(query) ?? false);
      return matchesRole && matchesAcc && matchesQuery;
    }).toList();
  }

  Future<void> _approve(AdminRegistrationApplicationDto app) async {
    if (app.userId == null) return;
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
    String? account = app.accountType;
    String? access = 'PREMIUM';
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

    if (confirmed != true) return;
    try {
      final updated = await _repository.updateFreeMechanicAccount(
        app.userId!,
        AdminAccountUpdateDto(accountTypeName: account, accessLevelName: access),
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
              _buildDropdownFilter(
                hint: 'Роль',
                value: _roleFilter,
                options: const ['ADMIN', 'MECHANIC', 'HEAD_MECHANIC', 'CLUB_OWNER'],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              const SizedBox(width: 8),
              _buildDropdownFilter(
                hint: 'Тип аккаунта',
                value: _accountFilter,
                options: AccountTypeName.values.map((e) => e.apiName).toList(),
                onChanged: (v) => setState(() => _accountFilter = v),
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

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String?>(
        value: value,
        items: [
          const DropdownMenuItem(value: null, child: Text('Все')),
          ...options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ],
        decoration: InputDecoration(labelText: hint),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCard(AdminRegistrationApplicationDto app) {
    final status = _resolveStatus(app);
    final role = app.role ?? '—';
    final account = app.accountType ?? '—';
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
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Роль: $role, аккаунт: $account'),
            if (app.clubName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Клуб: ${app.clubName}'),
              ),
            if (app.submittedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Отправлено: ${app.submittedAt}'),
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
    if (app.isVerified == true) return 'Одобрено';
    if (app.isActive == false || app.isVerified == false) return 'На модерации';
    return 'Черновик';
  }
}
