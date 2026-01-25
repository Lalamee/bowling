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
  final Set<String> _archivedIds = <String>{};
  String? _typeFilter;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _typeLabels = {
    'REGISTRATION_DECISION': 'Решение по регистрации',
    'ATTESTATION_DECISION': 'Решение по аттестации',
    'HELP_REQUEST': 'Запрос помощи',
    'SUPPLIER_COMPLAINT': 'Жалоба поставщику',
    'ACCESS_REQUEST': 'Запрос доступа',
    'USER_APPEAL': 'Обращение пользователя',
    'CLUB_TECH_SUPPORT': 'Клуб: запрос техподдержки',
    'CLUB_SUPPLIER_REFUSAL': 'Клуб: отказ поставщика',
    'CLUB_MECHANIC_FAILURE': 'Клуб: ремонт невозможен',
    'CLUB_LEGAL_ASSISTANCE': 'Клуб: юридическая помощь',
    'CLUB_SPECIALIST_ACCESS': 'Клуб: доступ к базе специалистов',
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
    final activeItems = items.where((item) => !_isArchived(item)).toList();
    final archivedItems = items.where(_isArchived).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
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
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (activeItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Горящие обращения отсутствуют')),
                  )
                else
                  ...activeItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCard(item),
                    ),
                  ),
                if (archivedItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text('Архив (${archivedItems.length})'),
                    children: archivedItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _buildCard(item, archived: true),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AdminAppealDto item, {bool archived = false}) {
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
        trailing: archived ? const Chip(label: Text('Ответ отправлен')) : Chip(label: Text(_typeLabel(item.type))),
        onTap: () => _showDetails(item),
      ),
    );
  }

  void _showDetails(AdminAppealDto item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обращение'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_typeLabel(item.type))),
                  if (item.requestId != null) Chip(label: Text('Заявка #${item.requestId}')),
                  if (item.clubId != null) Chip(label: Text('Клуб #${item.clubId}')),
                  if (item.mechanicId != null) Chip(label: Text('Механик #${item.mechanicId}')),
                ],
              ),
              if (item.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Создано: ${item.createdAt!.toLocal().toString().split('.').first}',
                  style: const TextStyle(color: AppColors.darkGray),
                ),
              ],
              if (item.message != null && item.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Сообщение', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Text(item.message!),
                ),
              ],
              if (item.payloadText != null && item.payloadText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Комментарий', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Text(item.payloadText!),
                ),
              ],
              if (item.payload != null && item.payload!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Данные обращения', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...item.payload!.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${e.key}: ${e.value}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Закрыть')),
          if (item.id != null && (item.clubId != null || item.mechanicId != null))
            FilledButton(
              onPressed: () => _replyToAppeal(item, ctx),
              child: const Text('Ответить'),
            ),
        ],
      ),
    );
  }

  Future<void> _replyToAppeal(AdminAppealDto item, BuildContext parentCtx) async {
    final controller = TextEditingController();
    final targetLabel = item.clubId != null ? 'клубу' : 'пользователю';
    final reply = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Ответить $targetLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Введите текст ответа',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ответ будет отправлен в оповещения пользователя.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reply == null || reply.isEmpty) return;
    try {
      await _repository.replyToAppeal(appealId: item.id!, message: reply);
      if (!mounted) return;
      if (item.id != null) {
        setState(() => _archivedIds.add(item.id!));
      }
      Navigator.of(parentCtx).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ответ отправлен')),
      );
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  String _typeLabel(String? type) {
    if (type == null) return '—';
    return _typeLabels[type.trim().toUpperCase()] ?? type;
  }

  bool _isArchived(AdminAppealDto item) {
    final id = item.id;
    if (id != null && _archivedIds.contains(id)) return true;
    final payload = item.payload ?? const {};
    const keys = ['reply', 'answer', 'response', 'adminReply', 'replyMessage'];
    final hasKey = keys.any((key) => payload.containsKey(key));
    if (hasKey) return true;
    final payloadText = item.payloadText ?? '';
    return payloadText.toLowerCase().contains('ответ:');
  }
}
