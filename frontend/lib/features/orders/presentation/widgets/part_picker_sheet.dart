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

  List<EquipmentComponentDto> _currentComponents = const [];
  final List<EquipmentComponentDto> _path = [];
  List<PartsCatalogResponseDto> _parts = const [];
  bool _loadingComponents = false;
  bool _loadingParts = false;

  bool get _canSearchParts => _path.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadComponents({int? parentId}) async {
    setState(() => _loadingComponents = true);
    try {
      final items = parentId == null
          ? await _componentRepository.fetchRoots()
          : await _componentRepository.fetchChildren(parentId);
      if (!mounted) return;
      setState(() {
        _currentComponents = items;
        _loadingComponents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentComponents = const [];
        _loadingComponents = false;
      });
    }
  }

  void _onComponentTap(EquipmentComponentDto component) {
    _path.add(component);
    _loadComponents(parentId: component.componentId);
    _runSearch(categoryCode: component.code);
  }

  void _onBackLevel() {
    if (_path.isEmpty) return;
    _path.removeLast();
    final parentId = _path.isNotEmpty ? _path.last.componentId : null;
    _loadComponents(parentId: parentId);
    if (_canSearchParts) {
      _runSearch(categoryCode: _path.last.code);
    } else {
      _resetParts();
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
        categoryCode: categoryCode ?? (_path.isNotEmpty ? _path.last.code : null),
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
            const SizedBox(height: 12),
            _buildBreadcrumbs(),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _loadingComponents
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentComponents.length,
                      itemBuilder: (context, index) {
                        final component = _currentComponents[index];
                        return GestureDetector(
                          onTap: () => _onComponentTap(component),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  component.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  component.category ?? '',
                                  style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (component.manufacturer != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      component.manufacturer!,
                                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                    ),
            ),
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
    if (_path.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Выберите категорию оборудования'),
        ],
      );
    }
    return Row(
      children: [
        IconButton(
          onPressed: _onBackLevel,
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: _path
                .map((c) => Chip(
                      label: Text(c.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
          ),
        ),
      ],
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
}
