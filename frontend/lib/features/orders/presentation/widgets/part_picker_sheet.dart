import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../api/api_service.dart';
import '../../../../core/repositories/equipment_component_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../models/equipment_component_dto.dart';
import '../../../../models/parts_catalog_response_dto.dart';
import '../../../../models/parts_search_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

class PartPickerSheet extends StatefulWidget {
  const PartPickerSheet({super.key});

  @override
  State<PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends State<PartPickerSheet> {
  final _componentRepository = EquipmentComponentRepository();
  final _api = ApiService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<_ComponentLevel> _levels = const [];
  EquipmentComponentDto? _leafSelection;
  List<PartsCatalogResponseDto> _parts = const [];
  bool _loadingParts = false;

  bool get _canSearchParts => _leafSelection != null;

  @override
  void initState() {
    super.initState();
    _loadComponents(levelIndex: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadComponents({int? parentId, required int levelIndex}) async {
    _setLevelLoading(levelIndex);
    try {
      final items = parentId == null
          ? await _componentRepository.fetchRoots()
          : await _componentRepository.fetchChildren(parentId);
      if (!mounted) return;
      _applyLoadedLevel(levelIndex, items);
    } catch (_) {
      if (!mounted) return;
      _applyLoadedLevel(levelIndex, const []);
    }
  }

  void _onSearchChanged(String value) {
    if (!_canSearchParts) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _resetParts() {
    if (!mounted) return;
    setState(() {
      _parts = const [];
      _loadingParts = false;
    });
  }

  Future<void> _runSearch({String? categoryCode}) async {
    if (!_canSearchParts) {
      _resetParts();
      return;
    }
    setState(() => _loadingParts = true);
    try {
      final dto = PartsSearchDto(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        categoryCode: categoryCode ?? _leafSelection?.code,
        size: 20,
      );
      final results = await _api.searchParts(dto);
      if (!mounted) return;
      setState(() {
        _parts = results;
        _loadingParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _parts = const [];
        _loadingParts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Подбор запчасти',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildSelectionSteps(),
            const SizedBox(height: 12),
            Expanded(child: _buildPartsSection()),
            CustomButton(
              text: 'Закрыть',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final selected = _levels.where((l) => l.selected != null).map((l) => l.selected!.name).toList();
    if (selected.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: selected.map((name) => Chip(label: Text(name, overflow: TextOverflow.ellipsis))).toList(),
    );
  }

  Widget _buildPartsSection() {
    if (!_canSearchParts) {
      return const Center(
        child: Text(
          'Сначала выберите категорию оборудования',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    if (_loadingParts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_parts.isEmpty) {
      return const Center(child: Text('Запчасти не найдены'));
    }

    return ListView.separated(
      itemCount: _parts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final part = _parts[index];
        final name = part.commonName ?? part.officialNameRu ?? part.officialNameEn ?? part.catalogNumber;
        final availability = part.availableQuantity ?? 0;
        return ListTile(
          title: Text(name),
          subtitle: Text('Кат. № ${part.catalogNumber} · Доступно: $availability'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, part),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск по каталожному номеру или названию',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            enabled: _canSearchParts,
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),
        Text(
          _canSearchParts
              ? 'Введите часть номера или названия, чтобы найти деталь в выбранной ветке.'
              : 'Сначала выберите бренд и последовательно дочерние категории.',
          style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectionSteps() {
    if (_levels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ...List.generate(_levels.length, (index) => _buildLevelCard(index)),
        if (_leafSelection != null) ...[
          const SizedBox(height: 8),
          const Text('Категория выбрана, можно искать детали.'),
        ],
        const SizedBox(height: 8),
        _buildBreadcrumbs(),
      ],
    );
  }

  Widget _buildLevelCard(int index) {
    final level = _levels[index];
    final title = index == 0 ? 'Шаг 1 — бренд / тип оборудования' : 'Шаг ${index + 1}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          level.loading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<EquipmentComponentDto>(
                  isExpanded: true,
                  value: level.selected,
                  hint: const Text('Выберите вариант'),
                  items: level.options
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _onComponentSelected(index, value);
                  },
                ),
        ],
      ),
    );
  }

  void _onComponentSelected(int levelIndex, EquipmentComponentDto component) {
    final updatedLevels = List<_ComponentLevel>.from(_levels);
    updatedLevels[levelIndex] = updatedLevels[levelIndex].copyWith(selected: component);
    if (updatedLevels.length > levelIndex + 1) {
      updatedLevels.removeRange(levelIndex + 1, updatedLevels.length);
    }

    setState(() {
      _levels = updatedLevels;
      _leafSelection = null;
    });
    _resetParts();
    _loadComponents(parentId: component.componentId, levelIndex: levelIndex + 1);
  }

  void _setLevelLoading(int levelIndex) {
    final updated = List<_ComponentLevel>.from(_levels);
    if (updated.length <= levelIndex) {
      updated.add(const _ComponentLevel(options: [], loading: true));
    } else {
      updated[levelIndex] = updated[levelIndex].copyWith(loading: true, options: const []);
    }
    setState(() => _levels = updated);
  }

  void _applyLoadedLevel(int levelIndex, List<EquipmentComponentDto> items) {
    final updated = List<_ComponentLevel>.from(_levels);

    if (items.isEmpty) {
      if (updated.length > levelIndex) {
        updated.removeRange(levelIndex, updated.length);
      }
      final leaf = updated.isNotEmpty ? updated.last.selected : null;
      setState(() {
        _levels = updated;
        _leafSelection = leaf;
      });
      if (leaf != null) {
        _runSearch(categoryCode: leaf.code);
      } else {
        _resetParts();
      }
      return;
    }

    if (updated.length <= levelIndex) {
      updated.add(_ComponentLevel(options: items));
    } else {
      updated[levelIndex] = _ComponentLevel(options: items);
    }

    setState(() {
      _levels = updated;
      _leafSelection = null;
    });
    _resetParts();
  }
}

class _ComponentLevel {
  final List<EquipmentComponentDto> options;
  final EquipmentComponentDto? selected;
  final bool loading;

  const _ComponentLevel({required this.options, this.selected, this.loading = false});

  _ComponentLevel copyWith({List<EquipmentComponentDto>? options, EquipmentComponentDto? selected, bool? loading}) {
    return _ComponentLevel(
      options: options ?? this.options,
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
    );
  }
}
