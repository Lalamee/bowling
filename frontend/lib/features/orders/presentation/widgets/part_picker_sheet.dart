import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../api/api_service.dart';
import '../../../../core/repositories/equipment_category_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../models/equipment_category_dto.dart';
import '../../../../models/parts_catalog_response_dto.dart';
import '../../../../models/parts_search_dto.dart';
import '../../../../shared/widgets/buttons/custom_button.dart';

class PartPickerSheet extends StatefulWidget {
  const PartPickerSheet({super.key});

  @override
  State<PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends State<PartPickerSheet> {
  final _categoryRepository = EquipmentCategoryRepository();
  final _api = ApiService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<EquipmentCategoryDto> _currentCategories = const [];
  final List<EquipmentCategoryDto> _path = [];
  List<PartsCatalogResponseDto> _parts = const [];
  bool _loadingComponents = false;
  bool _loadingParts = false;
  String? _selectedBrand;

  bool get _canSearchParts => _path.isNotEmpty && _path.last.level >= 3;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories({int? parentId}) async {
    setState(() => _loadingComponents = true);
    try {
      final items = parentId == null
          ? await _categoryRepository.fetchRoots()
          : await _categoryRepository.fetchChildren(
              parentId: parentId,
              brand: _selectedBrand,
            );
      if (!mounted) return;
      setState(() {
        _currentCategories = items;
        _loadingComponents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentCategories = const [];
        _loadingComponents = false;
      });
    }
  }

  Future<void> _onCategoryTap(EquipmentCategoryDto category) async {
    if (category.level == 1) {
      _selectedBrand = category.brand;
    }
    _path.add(category);
    await _loadCategories(parentId: category.id);
    if (category.level >= 3) {
      _runSearch(categoryCode: category.code ?? category.id.toString());
    } else {
      _resetParts();
    }
  }

  Future<void> _onBackLevel() async {
    if (_path.isEmpty) return;
    _path.removeLast();
    _selectedBrand = _path.isNotEmpty ? _path.first.brand : null;
    final parentId = _path.isNotEmpty ? _path.last.id : null;
    await _loadCategories(parentId: parentId);
    if (_path.isNotEmpty && _path.last.level >= 3) {
      final last = _path.last;
      _runSearch(categoryCode: last.code ?? last.id.toString());
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
    setState(() => _loadingParts = true);
    try {
      final dto = PartsSearchDto(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        categoryCode: categoryCode ??
            (_path.isNotEmpty ? _path.last.code ?? _path.last.id.toString() : null),
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
                hintText: 'Каталожный номер, название или ключевые слова',
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
                      itemCount: _currentCategories.length,
                      itemBuilder: (context, index) {
                        final category = _currentCategories[index];
                        return GestureDetector(
                          onTap: () => _onCategoryTap(category),
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
                                  category.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category.brand,
                                  style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                      label: Text(c.displayName, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _path.clear();
              _selectedBrand = null;
              _resetParts();
            });
            _loadCategories();
          },
          child: const Text('Сбросить'),
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final part = _parts[index];
        final name = part.commonName ?? part.officialNameRu ?? part.officialNameEn ?? part.catalogNumber;
        final availability = part.availableQuantity ?? 0;
        final serviceLifeParts = <String>[];
        if (part.normalServiceLife != null) {
          serviceLifeParts.add(part.normalServiceLife.toString());
        }
        if ((part.unit?.isNotEmpty ?? false)) {
          serviceLifeParts.add(part.unit!);
        }
        final serviceLifeText =
            serviceLifeParts.isNotEmpty ? 'Срок службы: ${serviceLifeParts.join(' ')}' : null;
        final manufacturerText =
            (part.manufacturerName?.isNotEmpty ?? false) ? 'Производитель: ${part.manufacturerName}' : null;
        final description = part.description;
        final imageUrl = part.imageUrl?.trim();

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.lightGray,
              backgroundImage:
                  (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Icon(Icons.image, color: AppColors.darkGray)
                  : null,
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (description?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.darkGray),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Кат. № ${part.catalogNumber} · Доступно: $availability'),
                ),
                if (serviceLifeText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(serviceLifeText),
                  ),
                if (manufacturerText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(manufacturerText),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, part),
          ),
        );
      },
    );
  }
}
