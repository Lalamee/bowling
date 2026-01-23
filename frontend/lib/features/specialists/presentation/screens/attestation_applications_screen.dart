import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/mechanic_directory_models.dart';

class AttestationApplicationsScreen extends StatefulWidget {
  const AttestationApplicationsScreen({super.key});

  @override
  State<AttestationApplicationsScreen> createState() => _AttestationApplicationsScreenState();
}

class _AttestationApplicationsScreenState extends State<AttestationApplicationsScreen> {
  final SpecialistsRepository _repository = SpecialistsRepository();
  final UserRepository _userRepository = UserRepository();

  List<AttestationApplication> _applications = [];
  int? _userId;
  int? _mechanicProfileId;
  int? _clubId;
  bool _loading = true;
  bool _submitting = false;
  bool _showArchive = false;

  final _formKey = GlobalKey<FormState>();
  MechanicGrade? _selectedGrade;
  final TextEditingController _experienceCtrl = TextEditingController();
  final TextEditingController _extraCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _experienceCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final me = await _userRepository.me();
      if (!mounted) return;
      _userId = _asInt(me['userId']) ?? _asInt(me['id']);
      final mechanicProfile = me['mechanicProfile'];
      if (mechanicProfile is Map) {
        final map = Map<String, dynamic>.from(mechanicProfile);
        _mechanicProfileId = _asInt(map['profileId']) ?? _asInt(map['mechanicProfileId']) ?? _asInt(map['id']);
        _clubId = _asInt(map['clubId']);
      }

      final apps = await _repository.getAttestationApplications();
      final attestationOnly = apps.where(_isAttestationApplication).toList();
      if (!mounted) return;
      setState(() {
        _applications = _userId != null
            ? attestationOnly.where((a) => a.userId == null || a.userId == _userId).toList()
            : attestationOnly;
        _loading = false;
      });
    } catch (e, s) {
      log('Failed to load attestation applications: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _applications = [];
        _loading = false;
      });
      showApiError(context, e);
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool _isAttestationApplication(AttestationApplication app) {
    return app.requestedGrade != null || app.approvedGrade != null;
  }

  Future<void> _submitApplication() async {
    if (_userId == null || _mechanicProfileId == null) {
      showApiError(context, 'В профиле не найдены идентификаторы механика. Обновите данные.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final experience = _experienceCtrl.text.trim();
    final extras = _extraCtrl.text.trim();
    final commentText = extras.isNotEmpty ? '$experience\nДополнительно: $extras' : experience;
    setState(() => _submitting = true);
    try {
      final dto = AttestationApplication(
        userId: _userId,
        mechanicProfileId: _mechanicProfileId,
        clubId: _clubId,
        requestedGrade: _selectedGrade,
        comment: commentText,
      );
      final created = await _repository.submitAttestationApplication(dto);
      if (!mounted) return;
      if (created != null) {
        _experienceCtrl.clear();
        _extraCtrl.clear();
        _selectedGrade = null;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка успешно отправлена')),
        );
        await _load();
      } else {
        showApiError(context, 'Не удалось отправить заявку');
      }
    } catch (e, s) {
      log('Failed to submit attestation: $e', stackTrace: s);
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Аттестация тех. специалиста',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MechanicGrade>(
                value: _selectedGrade,
                decoration: const InputDecoration(labelText: 'Желаемый грейд'),
                items: MechanicGrade.values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_gradeLabel(g)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedGrade = value),
                validator: (value) => value == null ? 'Выберите грейд' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experienceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Описание опыта и компетенций',
                  hintText: 'Укажите опыт, ключевые навыки и сильные стороны',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Добавьте описание опыта';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _extraCtrl,
                decoration: const InputDecoration(
                  labelText: 'Дополнительные сведения (при необходимости)',
                  hintText: 'Ссылки на дипломы, сертификаты, ссылки на работы',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submitApplication,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Подать заявку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleApplications = _applications.where((app) {
      final status = app.status;
      if (_showArchive) {
        return status == AttestationDecisionStatus.approved;
      }
      return status != AttestationDecisionStatus.approved;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Аттестация тех. специалиста')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _openForm,
        icon: const Icon(Icons.verified_user_outlined),
        label: const Text('Подать заявку'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Text('Актуальные (${_applications.where((app) => app.status != AttestationDecisionStatus.approved).length})'),
                    selected: !_showArchive,
                    onSelected: (_) => setState(() => _showArchive = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Text('Архив (${_applications.where((app) => app.status == AttestationDecisionStatus.approved).length})'),
                    selected: _showArchive,
                    onSelected: (_) => setState(() => _showArchive = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleApplications.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                _showArchive
                                    ? 'В архиве пока нет заявок на аттестацию'
                                    : 'У вас пока нет заявок на аттестацию',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: visibleApplications.length,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemBuilder: (_, index) => _buildTile(visibleApplications[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(AttestationApplication app) {
    final requested = app.requestedGrade != null ? _gradeLabel(app.requestedGrade!) : null;
    final approved = app.approvedGrade != null ? _gradeLabel(app.approvedGrade!) : null;
    final status = app.status != null ? _statusLabel(app.status!) : 'Статус не указан';
    final commentLabel = app.status == AttestationDecisionStatus.pending
        ? 'Описание опыта'
        : 'Комментарий Администрации';
    final mechanicName = app.mechanicName?.trim();
    final mechanicPhone = app.mechanicPhone?.trim();

    final submitted = app.submittedAt != null
        ? 'Подача: ${app.submittedAt!.toLocal().toString().split('.').first}'
        : null;
    final updated = app.updatedAt != null
        ? 'Обновлено: ${app.updatedAt!.toLocal().toString().split('.').first}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Заявка #${app.id ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (approved != null)
                  Chip(label: Text('Подтверждённый грейд: $approved'))
                else if (requested != null)
                  Chip(label: Text('Запрошенный грейд: $requested')),
                if (requested != null && approved != null && approved != requested)
                  Chip(label: Text('Запрошено: $requested')),
                if (app.clubId != null) Chip(label: Text('Клуб: ${app.clubId}')),
              ],
            ),
            if ((mechanicName != null && mechanicName.isNotEmpty) ||
                (mechanicPhone != null && mechanicPhone.isNotEmpty)) ...[
              const SizedBox(height: 6),
              if (mechanicName != null && mechanicName.isNotEmpty)
                Text('Механик: $mechanicName'),
              if (mechanicPhone != null && mechanicPhone.isNotEmpty)
                Text('Телефон: $mechanicPhone'),
            ],
            if (app.comment != null && app.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('$commentLabel:\n${app.comment}'),
            ],
            if (submitted != null || updated != null) ...[
              const SizedBox(height: 6),
              Text(
                [submitted, updated].whereType<String>().join(' • '),
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _gradeLabel(MechanicGrade grade) {
    switch (grade) {
      case MechanicGrade.junior:
        return 'JUNIOR';
      case MechanicGrade.middle:
        return 'MIDDLE';
      case MechanicGrade.senior:
        return 'SENIOR';
      case MechanicGrade.lead:
        return 'LEAD';
    }
  }

  String _statusLabel(AttestationDecisionStatus status) {
    switch (status) {
      case AttestationDecisionStatus.pending:
        return 'Рассматривается';
      case AttestationDecisionStatus.approved:
        return 'Одобрено';
      case AttestationDecisionStatus.rejected:
        return 'Отклонено';
    }
  }
}
