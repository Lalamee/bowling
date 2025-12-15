import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/repositories/admin_cabinet_repository.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/net_ui.dart';
import '../../../models/admin_complaint_dto.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final AdminCabinetRepository _repository = AdminCabinetRepository();
  bool _loading = true;
  bool _error = false;
  String? _statusFilter;
  bool? _resolvedFilter;
  List<AdminComplaintDto> _items = [];

  static const Map<String, String> _statusLabels = {
    'OPEN': 'Открыт',
    'IN_PROGRESS': 'В работе',
    'CLOSED': 'Закрыт',
  };

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
      final complaints = await _repository.listComplaints();
      if (!mounted) return;
      setState(() {
        _items = complaints;
        _loading = false;
      });
    } catch (e, s) {
      log('Failed to load complaints: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      showApiError(context, e);
    }
  }

  List<AdminComplaintDto> get _filtered {
    return _items.where((c) {
      final matchesStatus = _statusFilter == null || c.complaintStatus?.toLowerCase() == _statusFilter?.toLowerCase();
      final matchesResolved = _resolvedFilter == null || c.complaintResolved == _resolvedFilter;
      return matchesStatus && matchesResolved;
    }).toList();
  }

  Future<void> _updateStatus(AdminComplaintDto complaint) async {
    String? statusCtrl = complaint.complaintStatus;
    final notesCtrl = TextEditingController(text: complaint.resolutionNotes ?? '');
    bool resolved = complaint.complaintResolved ?? false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обновление статуса спора'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              value: statusCtrl,
              decoration: const InputDecoration(labelText: 'Статус'),
              items: const [
                DropdownMenuItem(value: 'OPEN', child: Text('Открыт')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('В работе')),
                DropdownMenuItem(value: 'CLOSED', child: Text('Закрыт')),
              ],
              onChanged: (v) => statusCtrl = v,
            ),
            CheckboxListTile(
              value: resolved,
              contentPadding: EdgeInsets.zero,
              title: const Text('Закрыт'),
              onChanged: (v) => resolved = v ?? resolved,
            ),
            TextFormField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Комментарий/решение'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (confirmed != true || complaint.reviewId == null) return;
    try {
      final updated = await _repository.updateComplaint(
        reviewId: complaint.reviewId!,
        status: statusCtrl?.trim().isEmpty ?? true ? null : statusCtrl?.trim(),
        resolved: resolved,
        notes: notesCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = _items.map((c) => c.reviewId == updated.reviewId ? updated : c).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Статус обновлён')));
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
        title: const Text('Споры с поставщиками'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AppColors.primary))],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить споры'),
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
                child: DropdownButtonFormField<String?>(
                  value: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Статус'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все')),
                    DropdownMenuItem(value: 'OPEN', child: Text('Открыт')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('В работе')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('Закрыт')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: _resolvedFilter,
                  decoration: const InputDecoration(labelText: 'Статус спора'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все')),
                    DropdownMenuItem(value: false, child: Text('Открыт')),
                    DropdownMenuItem(value: true, child: Text('Закрыт')),
                  ],
                  onChanged: (v) => setState(() => _resolvedFilter = v),
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

  Widget _buildCard(AdminComplaintDto item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.complaintTitle ?? 'Спор #${item.reviewId ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700))),
                Chip(label: Text(_statusLabels[item.complaintStatus?.toUpperCase()] ?? '—')),
              ],
            ),
            if (item.comment != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.comment!)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Клуб: ${item.clubId ?? '-'} | Поставщик: ${item.supplierId ?? '-'}'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Рейтинг: ${item.rating ?? '-'}'),
            ),
            if (item.resolutionNotes != null && item.resolutionNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Решение: ${item.resolutionNotes}'),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Изменить статус'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
