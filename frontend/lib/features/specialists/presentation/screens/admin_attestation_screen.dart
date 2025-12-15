import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/repositories/specialists_repository.dart';
import '../../../../../core/utils/net_ui.dart';
import '../../../../../models/mechanic_directory_models.dart';

class AdminAttestationScreen extends StatefulWidget {
  const AdminAttestationScreen({super.key});

  @override
  State<AdminAttestationScreen> createState() => _AdminAttestationScreenState();
}

class _AdminAttestationScreenState extends State<AdminAttestationScreen> {
  final SpecialistsRepository _repository = SpecialistsRepository();
  AttestationDecisionStatus? _statusFilter;
  MechanicGrade? _gradeFilter;
  final TextEditingController _regionFilterCtrl = TextEditingController();
  bool _loading = true;
  List<AttestationApplication> _applications = [];
  final Map<int, String> _profileRegions = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _regionFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final apps = await _repository.getAttestationApplications(status: _statusFilter);
      final enriched = await _attachRegions(apps);
      if (!mounted) return;
      setState(() {
        _applications = _gradeFilter == null
            ? enriched
            : enriched.where((a) => a.requestedGrade == _gradeFilter).toList();
        _loading = false;
      });
    } catch (e, s) {
      log('Failed to load attestation apps: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _applications = [];
        _loading = false;
      });
      showApiError(context, e);
    }
  }

  Future<List<AttestationApplication>> _attachRegions(List<AttestationApplication> apps) async {
    final regionFilter = _regionFilterCtrl.text.trim().toLowerCase();
    final result = <AttestationApplication>[];
    final idsToFetch = apps
        .map((a) => a.mechanicProfileId)
        .whereType<int>()
        .where((id) => !_profileRegions.containsKey(id))
        .toSet();

    if (idsToFetch.isNotEmpty) {
      await Future.wait(idsToFetch.map((id) async {
        try {
          final detail = await _repository.getDetail(id);
          if (detail?.region != null) {
            _profileRegions[id] = detail!.region!;
          }
        } catch (_) {
          // ignore enrichment errors, keep base data
        }
      }));
    }

    for (final app in apps) {
      final profileId = app.mechanicProfileId;
      if (regionFilter.isEmpty) {
        result.add(app);
      } else {
        final region = _profileRegions[profileId ?? -1]?.toLowerCase();
        if (region != null && region.contains(regionFilter)) {
          result.add(app);
        }
      }
    }
    return result;
  }

  Future<void> _changeDecision(AttestationApplication app, AttestationDecisionStatus status) async {
    if (app.id == null) {
      showApiError(context, 'Не найден идентификатор заявки');
      return;
    }
    MechanicGrade? grade = app.requestedGrade;
    final commentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(status == AttestationDecisionStatus.approved ? 'Одобрить заявку' : 'Отклонить заявку'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == AttestationDecisionStatus.approved)
                  DropdownButtonFormField<MechanicGrade?>(
                    value: grade,
                    decoration: const InputDecoration(labelText: 'Подтверждённый грейд'),
                    items: MechanicGrade.values
                        .map(
                          (g) => DropdownMenuItem<MechanicGrade?>(
                            value: g,
                            child: Text(g.toApiValue()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => grade = value,
                    validator: (value) => value == null ? 'Укажите грейд' : null,
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'Комментарий'),
                  maxLines: 3,
                  validator: (value) {
                    if (status == AttestationDecisionStatus.rejected && (value == null || value.trim().isEmpty)) {
                      return 'Укажите причину отказа';
                    }
                    return null;
                  },
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      final updated = await _repository.decideApplication(
        applicationId: app.id ?? 0,
        status: status,
        approvedGrade: status == AttestationDecisionStatus.approved ? grade : null,
        comment: commentCtrl.text.trim(),
      );
      if (!mounted) return;
      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус заявки обновлён')),
        );
        await _load();
      } else {
        showApiError(context, 'Не удалось обновить заявку');
      }
    } catch (e, s) {
      log('Failed to update decision: $e', stackTrace: s);
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на аттестацию (Администратор)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<AttestationDecisionStatus?>(
                      value: _statusFilter,
                      decoration: const InputDecoration(labelText: 'Статус'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все')),
                        DropdownMenuItem(value: AttestationDecisionStatus.pending, child: Text('В работе')),
                        DropdownMenuItem(value: AttestationDecisionStatus.approved, child: Text('Одобрены')),
                        DropdownMenuItem(value: AttestationDecisionStatus.rejected, child: Text('Отклонены')),
                      ],
                      onChanged: (value) => setState(() => _statusFilter = value),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _regionFilterCtrl,
                      decoration: const InputDecoration(labelText: 'Регион механика'),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<MechanicGrade?>(
                      value: _gradeFilter,
                      decoration: const InputDecoration(labelText: 'Запрошенный грейд'),
                      items: [
                        const DropdownMenuItem<MechanicGrade?>(value: null, child: Text('Любой')),
                        ...MechanicGrade.values
                            .map((g) => DropdownMenuItem<MechanicGrade?>(
                                  value: g,
                                  child: Text(_gradeLabel(g)),
                                ))
                            .toList(),
                      ],
                      onChanged: (value) => setState(() => _gradeFilter = value),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                    ? const Center(child: Text('Нет заявок по выбранным фильтрам'))
                    : ListView.builder(
                        itemCount: _applications.length,
                        itemBuilder: (_, index) => _buildTile(_applications[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(AttestationApplication app) {
    final subtitle = <String>[];
    final resolvedGrade = app.approvedGrade ?? app.requestedGrade;
    final region = app.mechanicProfileId != null ? _profileRegions[app.mechanicProfileId!] : null;
    if (resolvedGrade != null) subtitle.add('Грейд: ${_gradeLabel(resolvedGrade)}');
    if (app.submittedAt != null) subtitle.add('Подача: ${_formatDate(app.submittedAt!)}');
    if (app.comment != null && app.comment!.isNotEmpty) subtitle.add('Комментарий: ${app.comment}');
    if (region != null) subtitle.add('Регион: $region');

    return Card(
      child: ListTile(
        title: Text('Заявка #${app.id ?? '—'}'),
        subtitle: subtitle.isNotEmpty ? Text(subtitle.join('\n')) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(label: Text(_statusLabel(app.status))),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => _changeDecision(app, AttestationDecisionStatus.approved),
                  tooltip: 'Одобрить',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () => _changeDecision(app, AttestationDecisionStatus.rejected),
                  tooltip: 'Отклонить',
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showDetails(app, region: region, resolvedGrade: resolvedGrade),
      ),
    );
  }

  void _showDetails(AttestationApplication app, {String? region, MechanicGrade? resolvedGrade}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Заявка #${app.id ?? '—'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (app.status != null) Text('Статус: ${_statusLabel(app.status)}'),
            if (resolvedGrade != null) Text('Грейд: ${_gradeLabel(resolvedGrade)}'),
            if (region != null) Text('Регион: $region'),
            if (app.comment != null && app.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Комментарий: ${app.comment}'),
              ),
            if (app.submittedAt != null)
              Text('Подано: ${_formatDate(app.submittedAt!)}'),
            if (app.updatedAt != null)
              Text('Обновлено: ${_formatDate(app.updatedAt!)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  String _statusLabel(AttestationDecisionStatus? status) {
    switch (status) {
      case AttestationDecisionStatus.approved:
        return 'Одобрена';
      case AttestationDecisionStatus.rejected:
        return 'Отклонена';
      case AttestationDecisionStatus.pending:
      default:
        return 'В работе';
    }
  }

  String _gradeLabel(MechanicGrade grade) {
    switch (grade) {
      case MechanicGrade.junior:
        return 'Junior';
      case MechanicGrade.middle:
        return 'Middle';
      case MechanicGrade.senior:
        return 'Senior';
      case MechanicGrade.lead:
        return 'Lead';
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date.toLocal());
}
