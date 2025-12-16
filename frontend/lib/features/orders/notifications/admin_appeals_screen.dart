import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/repositories/admin_cabinet_repository.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/net_ui.dart';
import '../../../models/admin_appeal_dto.dart';

class AdminAppealsScreen extends StatefulWidget {
  const AdminAppealsScreen({super.key});

  @override
  State<AdminAppealsScreen> createState() => _AdminAppealsScreenState();
}

class _AdminAppealsScreenState extends State<AdminAppealsScreen> {
  final AdminCabinetRepository _repository = AdminCabinetRepository();
  bool _loading = true;
  bool _error = false;
  List<AdminAppealDto> _items = [];
  String? _typeFilter;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _typeLabels = {
    'REGISTRATION_DECISION': 'Решение по регистрации',
    'ATTESTATION_DECISION': 'Решение по аттестации',
    'HELP_REQUEST': 'Запрос помощи',
    'SUPPLIER_COMPLAINT': 'Жалоба поставщику',
    'ACCESS_REQUEST': 'Запрос доступа',
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
      final appeals = await _repository.listAppeals();
      if (!mounted) return;
      setState(() {
        _items = appeals;
        _loading = false;
      });
    } catch (e, s) {
      log('Failed to load appeals: $e', stackTrace: s);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      showApiError(context, e);
    }
  }

  List<AdminAppealDto> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _items.where((e) {
      final matchesType = _typeFilter == null || e.type?.toLowerCase() == _typeFilter?.toLowerCase();
      final matchesQuery = query.isEmpty ||
          (e.message?.toLowerCase().contains(query) ?? false) ||
          (e.payload?.values.any((value) => value.toString().toLowerCase().contains(query)) ?? false);
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Обращения и оповещения'),
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
            const Text('Не удалось загрузить обращения'),
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
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String?>(
                  value: _typeFilter,
                  decoration: const InputDecoration(labelText: 'Тип события'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все')),
                    ..._typeLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                  ],
                  onChanged: (v) => setState(() => _typeFilter = v),
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

  Widget _buildCard(AdminAppealDto item) {
    final subtitle = <String>[];
    if (item.requestId != null) subtitle.add('Заявка: ${item.requestId}');
    if (item.clubId != null) subtitle.add('Клуб: ${item.clubId}');
    if (item.mechanicId != null) subtitle.add('Механик: ${item.mechanicId}');
    if (item.createdAt != null) subtitle.add('Создано: ${item.createdAt!.toLocal().toString().split('.').first}');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(item.message ?? 'Оповещение ${item.id ?? ''}'),
        subtitle: subtitle.isNotEmpty ? Text(subtitle.join('\n')) : null,
        trailing: Chip(label: Text(_typeLabel(item.type))),
        onTap: () => _showDetails(item),
      ),
    );
  }

  void _showDetails(AdminAppealDto item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_typeLabel(item.type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.message != null) Text(item.message!),
            if (item.payload != null && item.payload!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Данные обращения:'),
              const SizedBox(height: 4),
              ...item.payload!.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Закрыть'))],
      ),
    );
  }

  String _typeLabel(String? type) {
    if (type == null) return '—';
    return _typeLabels[type.trim().toUpperCase()] ?? type;
  }
}

