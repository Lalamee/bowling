import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/repositories/admin_mechanics_repository.dart';
import '../../../../../core/repositories/admin_users_repository.dart';
import '../../../../../core/repositories/admin_cabinet_repository.dart';
import '../../../../../core/repositories/clubs_repository.dart';
import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/mechanic_club_link_request_dto.dart';
import '../../../../../models/admin_mechanic_status_change_dto.dart';
import '../../../../../models/admin_staff_status_update_dto.dart';
import '../../../../../models/admin_mechanic_account_change_dto.dart';
import '../../../../../models/free_mechanic_application_response_dto.dart';
import '../../../../../models/club_summary_dto.dart';
import '../../../../../models/mechanic_directory_models.dart';

class AdminMechanicsScreen extends StatefulWidget {
  const AdminMechanicsScreen({super.key});

  @override
  State<AdminMechanicsScreen> createState() => _AdminMechanicsScreenState();
}

class _AdminMechanicsScreenState extends State<AdminMechanicsScreen> {
  final AdminMechanicsRepository _mechanicsRepository = AdminMechanicsRepository();
  final AdminUsersRepository _usersRepository = AdminUsersRepository();
  final AdminCabinetRepository _cabinetRepository = AdminCabinetRepository();
  final ClubsRepository _clubsRepository = ClubsRepository();
  final SpecialistsRepository _specialistsRepository = SpecialistsRepository();

  static const Map<String, String> _accountLabels = {
    'INDIVIDUAL': 'Механик',
    'CLUB_OWNER': 'Владелец',
    'CLUB_MANAGER': 'Менеджер клуба',
    'FREE_MECHANIC_BASIC': 'Свободный механик (базовый)',
    'FREE_MECHANIC_PREMIUM': 'Свободный механик (премиум)',
    'MAIN_ADMIN': 'Администрация сервиса',
  };

  bool _isLoading = true;
  bool _hasError = false;
  List<_PendingMechanic> _pending = [];
  List<_ClubMechanicsSection> _sections = [];
  List<AdminMechanicStatusChangeDto> _statusRequests = [];
  List<_ClubOption> _clubOptions = [];
  List<FreeMechanicApplicationResponseDto> _freeMechanics = [];
  Map<int, MechanicDirectoryDetail> _freeMechanicDetails = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    List<_PendingMechanic> pending = [];
    List<_ClubMechanicsSection> sections = [];
    List<AdminMechanicStatusChangeDto> statusRequests = [];
    List<_ClubOption> clubOptions = [];
    List<FreeMechanicApplicationResponseDto> freeMechanics = [];
    Map<int, MechanicDirectoryDetail> freeMechanicDetails = Map.of(_freeMechanicDetails);
    bool overviewFailed = false;
    bool freeMechanicsFailed = false;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final futures = await Future.wait([
        _mechanicsRepository.getOverview().catchError((e, s) {
          overviewFailed = true;
          log('Failed to load admin mechanics overview: $e', stackTrace: s);
          return AdminMechanicsOverview.empty();
        }),
        _clubsRepository.getClubs().catchError((e, s) {
          log('Failed to load admin clubs list: $e', stackTrace: s);
          return <ClubSummaryDto>[];
        }),
        _cabinetRepository.listMechanicStatusChanges().catchError((e, s) {
          log('Failed to load mechanic status changes: $e', stackTrace: s);
          return <AdminMechanicStatusChangeDto>[];
        }),
        _cabinetRepository.listFreeMechanicApplications().catchError((e, s) {
          freeMechanicsFailed = true;
          log('Failed to load free mechanic applications: $e', stackTrace: s);
          return <FreeMechanicApplicationResponseDto>[];
        }),
      ]);

      final overview = futures[0] as AdminMechanicsOverview;
      final clubs = futures[1] as List<ClubSummaryDto>;
      statusRequests = futures[2] as List<AdminMechanicStatusChangeDto>;
      freeMechanics = futures[3] as List<FreeMechanicApplicationResponseDto>;
      freeMechanicDetails = await _loadFreeMechanicDetails(freeMechanics, freeMechanicDetails);

      pending = overview.pending.map(_mapPending).where((m) => m.userId != null).toList();
      sections = overview.clubs.map(_mapClub).toList();
      sections.sort((a, b) => (a.clubName ?? '').toLowerCase().compareTo((b.clubName ?? '').toLowerCase()));
      clubOptions = clubs.map((c) => _ClubOption(id: c.id, name: c.name)).toList();
    } catch (e, s) {
      overviewFailed = true;
      freeMechanicsFailed = true;
      log('Failed to load admin mechanics overview: $e', stackTrace: s);
    }

    if (!mounted) return;

    setState(() {
      _pending = pending;
      _sections = sections;
      _statusRequests = statusRequests;
      _clubOptions = clubOptions;
      _freeMechanics = freeMechanics;
      _freeMechanicDetails = freeMechanicDetails;
      _isLoading = false;
      _hasError = overviewFailed && freeMechanicsFailed;
    });

    if (_hasError) {
      showApiError(context, 'Не удалось загрузить данные по механикам');
    }
  }

  _PendingMechanic _mapPending(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    return _PendingMechanic(
      userId: _asInt(map['userId']),
      profileId: _asInt(map['profileId']),
      name: _asString(map['fullName']) ?? 'Без имени',
      phone: _asString(map['phone']),
      clubId: _asInt(map['requestedClubId']),
      clubName: _asString(map['requestedClubName']),
      clubAddress: _asString(map['requestedClubAddress']),
      createdAt: _asString(map['createdAt']),
      isActive: _asBool(map['isActive']),
      isVerified: _asBool(map['isVerified']),
      isDataVerified: _asBool(map['isDataVerified']),
    );
  }

  _ClubMechanicsSection _mapClub(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    final mechanicsRaw = map['mechanics'];
    final mechanics = mechanicsRaw is List ? mechanicsRaw.map(_mapMechanic).toList() : <_MechanicInfo>[];
    return _ClubMechanicsSection(
      clubId: _asInt(map['clubId']),
      clubName: _asString(map['clubName']) ?? 'Клуб',
      address: _asString(map['address']),
      contactPhone: _asString(map['contactPhone']),
      contactEmail: _asString(map['contactEmail']),
      mechanics: mechanics,
    );
  }

  _MechanicInfo _mapMechanic(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    return _MechanicInfo(
      userId: _asInt(map['userId']),
      profileId: _asInt(map['profileId']),
      name: _asString(map['fullName']) ?? 'Без имени',
      phone: _asString(map['phone']),
      isActive: _asBool(map['isActive']),
      isVerified: _asBool(map['isVerified']),
      isDataVerified: _asBool(map['isDataVerified']),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  void _toggleSection(int index) {
    setState(() {
      _sections[index].isOpen = !_sections[index].isOpen;
    });
  }

  Future<Map<int, MechanicDirectoryDetail>> _loadFreeMechanicDetails(
    List<FreeMechanicApplicationResponseDto> mechanics,
    Map<int, MechanicDirectoryDetail> existing,
  ) async {
    final idsToFetch = mechanics
        .map((m) => m.mechanicProfileId)
        .whereType<int>()
        .where((id) => !existing.containsKey(id))
        .toSet();

    if (idsToFetch.isEmpty) {
      return existing;
    }

    await Future.wait(idsToFetch.map((id) async {
      try {
        final detail = await _specialistsRepository.getDetail(id);
        if (detail != null) {
          existing[id] = detail;
        }
      } catch (_) {
        // ignore, keep base info
      }
    }));

    return existing;
  }

  Future<void> _approvePending(int index) async {
    final mechanic = _pending[index];
    if (mechanic.userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение механика'),
        content: Text('Подтвердить регистрацию механика "${mechanic.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Подтвердить')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      mechanic.isProcessing = true;
    });

    try {
      final success = await _usersRepository.verify('${mechanic.userId}');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Механик подтверждён')),
        );
        await _loadData();
      } else {
        throw Exception('Не удалось подтвердить механика');
      }
    } catch (e, s) {
      log('Failed to verify mechanic ${mechanic.userId}: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        mechanic.isProcessing = false;
      });
      showApiError(context, e);
    }
  }

  Future<void> _updateStatusRequest(AdminMechanicStatusChangeDto request,
      {required bool active, required bool restricted}) async {
    if (request.staffId == null) return;
    try {
      final updated = await _cabinetRepository.updateMechanicStatus(
        staffId: request.staffId!,
        update: AdminStaffStatusUpdateDto(active: active, infoAccessRestricted: restricted),
      );
      if (!mounted) return;
      setState(() {
        _statusRequests = _statusRequests.map((r) => r.staffId == updated.staffId ? updated : r).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Статус обновлён')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _detachFromClub(_MechanicInfo mechanic, int? clubId) async {
    if (mechanic.profileId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отвязка механика'),
        content: Text('Убрать "${mechanic.name}" из клуба?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Убрать')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _cabinetRepository.changeMechanicClubLink(
        mechanic.profileId!,
        MechanicClubLinkRequestDto(clubId: clubId, attach: false),
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Механик отвязан')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _attachToClub(_MechanicInfo mechanic) async {
    if (mechanic.profileId == null) return;
    int? selected = _clubOptions.isNotEmpty ? _clubOptions.first.id : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Назначить клуб'),
        content: DropdownButtonFormField<int?>(
          value: selected,
          decoration: const InputDecoration(labelText: 'Клуб'),
          items: _clubOptions
              .map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name ?? 'Клуб ${c.id}'),
                  ))
              .toList(),
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _cabinetRepository.changeMechanicClubLink(
        mechanic.profileId!,
        MechanicClubLinkRequestDto(clubId: selected, attach: true),
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Механик назначен в клуб')));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _convertToFree(_MechanicInfo mechanic) async {
    if (mechanic.userId == null) return;
    String? account = 'FREE_MECHANIC_BASIC';
    String? access = 'BASIC';
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Перевод в свободные агенты'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: account,
                decoration: const InputDecoration(labelText: 'Тип аккаунта'),
                items: const [
                  DropdownMenuItem(value: 'FREE_MECHANIC_BASIC', child: Text('Свободный механик (базовый)')),
                  DropdownMenuItem(value: 'FREE_MECHANIC_PREMIUM', child: Text('Свободный механик (премиум)')),
                ],
                isExpanded: true,
                onChanged: (v) => account = v,
                validator: (v) => v == null ? 'Укажите тип' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: access,
                decoration: const InputDecoration(labelText: 'Уровень доступа'),
                items: const [
                  DropdownMenuItem(value: 'PREMIUM', child: Text('Премиум')),
                  DropdownMenuItem(value: 'BASIC', child: Text('Базовый')),
                ],
                isExpanded: true,
                onChanged: (v) => access = v,
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
            child: const Text('Перевести'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _cabinetRepository.convertMechanicAccount(
        mechanic.userId!,
        AdminMechanicAccountChangeDto(accountTypeName: account, accessLevelName: access, attachToClub: false),
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Переведён в свободные агенты')));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'База свободных агентов',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Не удалось загрузить список механиков', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pending.isEmpty && _sections.isEmpty && _freeMechanics.isEmpty && _statusRequests.isEmpty) {
      return const Center(child: Text('Свободные агенты не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _buildFreeMechanicsSection(),
          const SizedBox(height: 16),
          if (_statusRequests.isNotEmpty) ...[
            _buildStatusRequests(),
            const SizedBox(height: 16),
          ],
          if (_pending.isNotEmpty) ...[
            _buildPendingSection(),
            const SizedBox(height: 16),
          ],
          if (_sections.isNotEmpty)
            for (var i = 0; i < _sections.length; i++) ...[
              _buildSectionCard(_sections[i], i),
              if (i < _sections.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildFreeMechanicsSection() {
    final freeAgents = _freeMechanics
        .where(
          (m) => (m.accountType?.toUpperCase().contains('FREE_MECHANIC') ?? false),
        )
        .toList();

    if (freeAgents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: const Text(
          'Свободные агенты не найдены',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Свободные агенты',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Список доступен только для просмотра',
            style: TextStyle(fontSize: 12, color: AppColors.darkGray),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < freeAgents.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildFreeMechanicTile(freeAgents[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeMechanicTile(FreeMechanicApplicationResponseDto mechanic) {
    final info = <String>[];
    if (mechanic.phone?.isNotEmpty == true) info.add(mechanic.phone!);
    if (mechanic.submittedAt != null) {
      info.add('Заявка: ${_formatDate(mechanic.submittedAt!)}');
    }
    final status = mechanic.status?.toUpperCase();
    final statusLabel = _freeStatusLabel(status);
    final detail = mechanic.mechanicProfileId != null ? _freeMechanicDetails[mechanic.mechanicProfileId!] : null;
    final statusChips = _buildFreeMechanicStatusChips(mechanic, statusLabel, detail);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mechanic.fullName ?? 'Без имени',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info.join(' • '),
              style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
              softWrap: true,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusChips,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: detail == null ? null : () => _showFreeMechanicDetails(mechanic, detail),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Анкета механика'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFreeMechanicDetails(FreeMechanicApplicationResponseDto mechanic, MechanicDirectoryDetail detail) {
    final rows = <Widget>[];

    void addRow(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('$label: ${value.trim()}'),
      ));
    }

    addRow('ФИО', detail.fullName ?? mechanic.fullName);
    addRow('Телефон', mechanic.phone);
    addRow('Регион', detail.region);
    addRow('Специализация', detail.specialization);
    if (detail.totalExperienceYears != null) {
      addRow('Общий стаж', '${detail.totalExperienceYears} лет');
    }
    if (detail.bowlingExperienceYears != null) {
      addRow('Стаж в боулинге', '${detail.bowlingExperienceYears} лет');
    }
    if (detail.isEntrepreneur != null) {
      addRow('Статус', detail.isEntrepreneur == true ? 'ИП' : 'Самозанятый');
    }
    if (detail.rating != null) {
      addRow('Рейтинг', detail.rating!.toStringAsFixed(1));
    }
    if (detail.certifications.isNotEmpty) {
      final certs = detail.certifications
          .map((cert) => cert.title)
          .where((title) => title != null && title.trim().isNotEmpty)
          .map((title) => title!.trim())
          .toList();
      if (certs.isNotEmpty) {
        addRow('Сертификаты', certs.join(', '));
      }
    }
    if (detail.workHistory.isNotEmpty) {
      final history = detail.workHistory
          .map((entry) => entry.organization)
          .where((name) => name != null && name.trim().isNotEmpty)
          .map((name) => name!.trim())
          .toList();
      if (history.isNotEmpty) {
        addRow('Опыт работы', history.join(', '));
      }
    }
    if (detail.relatedClubs.isNotEmpty) {
      final clubs = detail.relatedClubs
          .map((club) => club.fullName)
          .where((name) => name != null && name.trim().isNotEmpty)
          .map((name) => name!.trim())
          .toList();
      if (clubs.isNotEmpty) {
        addRow('Клубы', clubs.join(', '));
      }
    }
    addRow('Аттестация', detail.attestationStatus);

    final content = rows.isNotEmpty ? rows : const [Text('Данные анкеты пока не заполнены')];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Анкета механика'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  List<Widget> _buildFreeMechanicStatusChips(
    FreeMechanicApplicationResponseDto mechanic,
    String statusLabel,
    MechanicDirectoryDetail? detail,
  ) {
    return [
      Chip(label: Text(statusLabel)),
      Chip(label: Text(_accountLabel(mechanic.accountType))),
      Chip(
        label: Text(mechanic.isActive == true ? 'Аккаунт активен' : 'Аккаунт отключён'),
      ),
      Chip(
        label: Text(mechanic.isVerified == true ? 'Аккаунт подтверждён' : 'Аккаунт не подтверждён'),
      ),
      Chip(
        label: Text(mechanic.isProfileVerified == true ? 'Профиль подтверждён' : 'Профиль не подтверждён'),
      ),
      if (detail?.attestationStatus != null && detail!.attestationStatus!.trim().isNotEmpty)
        Chip(label: Text('Аттестация: ${detail.attestationStatus!.trim()}')),
    ];
  }

  Widget _buildPendingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ожидают подтверждения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _pending.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildPendingTile(_pending[i], i),
          ],
        ],
      ),
    );
  }

  Widget _statusTile(AdminMechanicStatusChangeDto request) {
    final title = request.clubName ?? 'Клуб ${request.clubId ?? '-'}';
    bool active = request.isActive ?? true;
    bool restricted = request.infoAccessRestricted ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Статус сотрудника: ${request.role ?? '—'}'),
          Row(
            children: [
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  title: const Text('Активен'),
                  onChanged: (v) => active = v,
                ),
              ),
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: restricted,
                  title: const Text('Доступ ограничен'),
                  onChanged: (v) => restricted = v,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: request.staffId == null
                  ? null
                  : () => _updateStatusRequest(request, active: active, restricted: restricted),
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRequests() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус доступа механиков',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          for (final req in _statusRequests) ...[
            _statusTile(req),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingTile(_PendingMechanic mechanic, int index) {
    final info = <String>[];
    if (mechanic.phone != null) {
      info.add(mechanic.phone!);
    }
    if (mechanic.clubName != null) {
      info.add('Клуб: ${mechanic.clubName}');
    }
    if (mechanic.createdAt != null) {
      info.add('Заявка от ${mechanic.createdAt}');
    }

    final status = <String>[];
    if (mechanic.isActive == false) {
      status.add('Аккаунт отключён');
    }
    if (mechanic.isVerified != true || mechanic.isDataVerified != true) {
      status.add('Требует подтверждения');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mechanic.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(info.join(' • '), style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
          ],
          if (status.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(status.join(' • '), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: (mechanic.userId == null || mechanic.isProcessing) ? null : () => _approvePending(index),
              icon: mechanic.isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(mechanic.isProcessing ? 'Обработка…' : 'Подтвердить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_ClubMechanicsSection section, int index) {
    final borderColor = section.isOpen ? AppColors.primary : AppColors.lightGray;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(index),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.clubName ?? 'Клуб',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                  Icon(
                    section.isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkGray,
                  ),
                ],
              ),
            ),
          ),
          if (section.isOpen) const Divider(height: 1),
          if (section.isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildSectionContent(section),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(_ClubMechanicsSection section) {
    final children = <Widget>[
      _sectionTitle('Контактная информация'),
      _infoTile(Icons.place_outlined, section.address ?? '—'),
    ];

    if (section.contactPhone != null && section.contactPhone!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(_infoTile(Icons.phone, section.contactPhone!.trim()));
    }
    if (section.contactEmail != null && section.contactEmail!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(_infoTile(Icons.email_outlined, section.contactEmail!.trim()));
    }

    children.add(const SizedBox(height: 16));
    children.add(_sectionTitle('Механики клуба'));

    if (section.mechanics.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Механики не назначены')),
      ));
    } else {
      children.addAll(_buildMechanicTiles(section.mechanics));
    }

    children.add(const SizedBox(height: 16));
    children.add(
      SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, Routes.adminOrders),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.history_rounded),
          label: const Text('История заказов клуба'),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _buildMechanicTiles(List<_MechanicInfo> mechanics) {
    final tiles = <Widget>[];
    for (var i = 0; i < mechanics.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }
      tiles.add(_mechanicTile(mechanics[i]));
    }
    return tiles;
  }

  Widget _mechanicTile(_MechanicInfo mechanic) {
    final details = <String>[];
    if (mechanic.phone != null) {
      details.add(mechanic.phone!);
    }

    final statuses = <String>[];
    if (mechanic.isActive == false) {
      statuses.add('Аккаунт отключён');
    }
    if (mechanic.isVerified != true) {
      statuses.add('Не подтверждён');
    } else if (mechanic.isDataVerified != true) {
      statuses.add('Данные не подтверждены');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mechanic.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.join(' • '),
              style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
            ),
          ],
          if (statuses.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              statuses.join(' • '),
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: mechanic.profileId == null ? null : () => _detachFromClub(mechanic, null),
                icon: const Icon(Icons.link_off),
                label: const Text('Убрать из клуба'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: mechanic.profileId == null ? null : () => _attachToClub(mechanic),
                icon: const Icon(Icons.add_business),
                label: const Text('Назначить клуб'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: mechanic.userId == null ? null : () => _convertToFree(mechanic),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('В свободные'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
    );
  }

  String _freeStatusLabel(String? status) {
    switch (status) {
      case 'APPROVED':
        return 'Одобрена';
      case 'REJECTED':
        return 'Отклонена';
      default:
        return 'В обработке';
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date.toLocal());

  String _accountLabel(String? account) {
    if (account == null) return '—';
    final key = account.trim().toUpperCase();
    return _accountLabels[key] ?? account;
  }
}

class _PendingMechanic {
  final int? userId;
  final int? profileId;
  final String name;
  final String? phone;
  final int? clubId;
  final String? clubName;
  final String? clubAddress;
  final String? createdAt;
  final bool? isActive;
  final bool? isVerified;
  final bool? isDataVerified;
  bool isProcessing = false;

  _PendingMechanic({
    required this.userId,
    required this.profileId,
    required this.name,
    this.phone,
    this.clubId,
    this.clubName,
    this.clubAddress,
    this.createdAt,
    this.isActive,
    this.isVerified,
    this.isDataVerified,
  });
}

class _ClubMechanicsSection {
  final int? clubId;
  final String? clubName;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final List<_MechanicInfo> mechanics;
  bool isOpen = false;

  _ClubMechanicsSection({
    required this.clubId,
    required this.clubName,
    required this.address,
    required this.contactPhone,
    required this.contactEmail,
    required this.mechanics,
  });
}

class _MechanicInfo {
  final int? userId;
  final int? profileId;
  final String name;
  final String? phone;
  final bool? isActive;
  final bool? isVerified;
  final bool? isDataVerified;

  _MechanicInfo({
    required this.userId,
    required this.profileId,
    required this.name,
    this.phone,
    this.isActive,
    this.isVerified,
    this.isDataVerified,
  });
}

class _ClubOption {
  final int id;
  final String name;

  _ClubOption({required this.id, required this.name});
}
