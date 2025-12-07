import 'package:flutter/material.dart';

import '../../../core/repositories/inventory_repository.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/net_ui.dart';
import '../../../core/utils/personal_inventory_filter.dart';
import '../../../core/utils/bottom_nav.dart';
import '../../../core/routing/routes.dart';
import '../../../models/part_dto.dart';
import '../../../models/warehouse_summary_dto.dart';
import '../../../shared/widgets/nav/app_bottom_nav.dart';

class PersonalWarehouseScreen extends StatefulWidget {
  final InventoryRepository? repository;

  const PersonalWarehouseScreen({super.key, this.repository});

  @override
  State<PersonalWarehouseScreen> createState() => _PersonalWarehouseScreenState();
}

class _PersonalWarehouseScreenState extends State<PersonalWarehouseScreen> {
  late final InventoryRepository _repo;
  final _searchCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  WarehouseSummaryDto? _warehouse;
  List<PartDto> _rawInventory = const [];
  List<PartDto> _filteredInventory = const [];
  List<String> _suggestions = const [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _onlyUnique = false;
  bool _onlyShortage = false;
  bool _onlyExpired = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? InventoryRepository();
    _loadWarehouseAndInventory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _categoryCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouseAndInventory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final warehouses = await _repo.getWarehouses();
      final personal = warehouses.firstWhere(
        (w) => w.warehouseType.toUpperCase() == 'PERSONAL' || w.personalAccess,
        orElse: () => throw StateError('Личный склад не найден'),
      );
      _warehouse = personal;
      await _fetchInventory(query: '');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  Future<void> _fetchInventory({required String query}) async {
    final warehouseId = _warehouse?.warehouseId;
    if (warehouseId == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _repo.getWarehouseInventory(
        warehouseId: warehouseId,
        query: query,
        category: _categoryCtrl.text.trim(),
      );
      if (!mounted) return;
      _rawInventory = data;
      _applyFilters();
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  void _applyFilters() {
    final filtered = PersonalInventoryFilter.apply(
      _rawInventory,
      query: _searchCtrl.text,
      onlyUnique: _onlyUnique,
      onlyShortage: _onlyShortage,
      onlyExpiredCheck: _onlyExpired,
      categoryFragment: _categoryCtrl.text,
    );
    final normalizedQuery = _searchCtrl.text.trim().toLowerCase();
    final suggestionPool = _rawInventory.where((part) {
      if (normalizedQuery.isEmpty) return false;
      return part.catalogNumber.toLowerCase().contains(normalizedQuery) ||
          (part.commonName?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (part.officialNameRu?.toLowerCase().contains(normalizedQuery) ?? false);
    }).map(_displayName).toSet().take(5).toList();

    setState(() {
      _filteredInventory = filtered;
      _suggestions = suggestionPool;
    });
  }

  void _toggleUnique(bool value) {
    _onlyUnique = value;
    _applyFilters();
  }

  void _toggleShortage(bool value) {
    _onlyShortage = value;
    _applyFilters();
  }

  void _toggleExpired(bool value) {
    _onlyExpired = value;
    _applyFilters();
  }

  void _openDetails(PartDto part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_displayName(part), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _buildDetailRow('Каталожный номер', part.catalogNumber),
              _buildDetailRow('Официальное название (RU)', part.officialNameRu),
              _buildDetailRow('Официальное название (EN)', part.officialNameEn),
              _buildDetailRow('Common name', part.commonName),
              _buildDetailRow('Количество / Резерв', _quantityText(part)),
              _buildDetailRow('Уникальная деталь', part.isUnique == true ? 'Да' : 'Нет'),
              _buildDetailRow('Адрес хранения', _locationText(part)),
              _buildDetailRow('Последняя проверка', part.lastChecked != null ? _formatDate(part.lastChecked!) : 'не указано'),
              _buildDetailRow('Заметки', part.notes),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, Routes.createMaintenanceRequest);
                  },
                  icon: const Icon(Icons.assignment_add),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  label: const Text('Создать заявку на обслуживание'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _displayName(PartDto part) {
    return part.commonName?.trim().isNotEmpty == true
        ? part.commonName!.trim()
        : part.officialNameRu?.trim().isNotEmpty == true
            ? part.officialNameRu!.trim()
            : part.officialNameEn?.trim().isNotEmpty == true
                ? part.officialNameEn!.trim()
                : part.catalogNumber;
  }

  String _quantityText(PartDto part) {
    final q = part.quantity?.toString() ?? '-';
    final r = part.reservedQuantity?.toString() ?? '0';
    return '$q / $r';
  }

  String _locationText(PartDto part) {
    final locations = <String>[];
    if (part.location != null && part.location!.trim().isNotEmpty) {
      locations.add(part.location!.trim());
    }
    if (part.cellCode != null && part.cellCode!.trim().isNotEmpty) {
      locations.add('Ячейка ${part.cellCode}');
    }
    if (part.shelfCode != null && part.shelfCode!.trim().isNotEmpty) {
      locations.add('Стеллаж ${part.shelfCode}');
    }
    if (part.laneNumber != null) {
      locations.add('Дорожка №${part.laneNumber}');
    }
    return locations.isEmpty ? '-' : locations.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildInventoryCard(PartDto part) {
    final subtitleStyle = const TextStyle(fontSize: 13, color: AppColors.darkGray);
    final shortage = part.quantity != null && part.reservedQuantity != null && part.quantity! <= part.reservedQuantity!;
    final note = part.notes?.trim();
    return InkWell(
      onTap: () => _openDetails(part),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: shortage ? Colors.orange : const Color(0xFFE6E6E6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_displayName(part), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('Каталожный номер: ${part.catalogNumber}', style: subtitleStyle),
            if (part.officialNameRu != null && part.officialNameRu!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Название (RU): ${part.officialNameRu}', style: subtitleStyle),
              ),
            if (part.officialNameEn != null && part.officialNameEn!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Название (EN): ${part.officialNameEn}', style: subtitleStyle),
              ),
            if (part.commonName != null && part.commonName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Неофициальное: ${part.commonName}', style: subtitleStyle),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Количество: ${part.quantity ?? '-'} | Резерв: ${part.reservedQuantity ?? 0}', style: subtitleStyle),
            ),
            if (part.isUnique == true)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.deepPurple, size: 16),
                    const SizedBox(width: 6),
                    Text('Уникальная деталь', style: subtitleStyle),
                  ],
                ),
              ),
            if (part.lastChecked != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Проверено: ${_formatDate(part.lastChecked!)}', style: subtitleStyle),
              ),
            if (part.location != null || part.cellCode != null || part.shelfCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Адрес хранения: ${_locationText(part)}', style: subtitleStyle),
              ),
            if (note != null && note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Заметки: $note', style: subtitleStyle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          label: const Text('Уникальные'),
          selected: _onlyUnique,
          onSelected: (v) => _toggleUnique(v),
        ),
        FilterChip(
          label: const Text('Низкий остаток'),
          selected: _onlyShortage,
          onSelected: (v) => _toggleShortage(v),
        ),
        FilterChip(
          label: const Text('Давно не проверяли'),
          selected: _onlyExpired,
          onSelected: (v) => _toggleExpired(v),
        ),
      ],
    );
  }

  Widget _buildWarehouseHeader() {
    final warehouseTitle = _warehouse?.title ?? 'Личный ZIP-склад';
    final description = _warehouse?.description;
    final location = _warehouse?.locationReference;
    final stats = <String>[];
    if (_warehouse?.totalPositions != null) {
      stats.add('Позиций: ${_warehouse!.totalPositions}');
    }
    if (_warehouse?.lowStockPositions != null && _warehouse!.lowStockPositions! > 0) {
      stats.add('Низкий остаток: ${_warehouse!.lowStockPositions}');
    }
    if (_warehouse?.reservedPositions != null) {
      stats.add('В резерве: ${_warehouse!.reservedPositions}');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(warehouseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (_warehouse != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _warehouse!.warehouseType.toUpperCase() == 'PERSONAL'
                    ? 'Персональный ZIP-склад свободного механика'
                    : 'Склад',
                style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
              ),
            ),
          if (location != null && location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Адрес хранения: $location', style: const TextStyle(fontSize: 13)),
            ),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(description, style: const TextStyle(color: AppColors.darkGray, fontSize: 13)),
            ),
          if (stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s),
                    onPressed: () {
                      _searchCtrl.text = s;
                      _searchCtrl.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
                      _applyFilters();
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Личный ZIP-склад', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [IconButton(onPressed: _loadWarehouseAndInventory, icon: const Icon(Icons.sync, color: AppColors.primary))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarehouseHeader(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            _buildSuggestionRow(),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadWarehouseAndInventory,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              const Center(child: Text('Не удалось загрузить склад')),
                              const SizedBox(height: 8),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _loadWarehouseAndInventory,
                                  child: const Text('Повторить'),
                                ),
                              ),
                            ],
                          )
                        : _filteredInventory.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 60),
                                  Center(child: Text('На складе нет подходящих позиций')),
                                ],
                              )
                            : ListView.separated(
                                itemBuilder: (_, i) => _buildInventoryCard(_filteredInventory[i]),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemCount: _filteredInventory.length,
                              ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: (i) => BottomNavDirect.go(context, 2, i)),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Поиск по каталожному номеру или названию',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (value) {
            _applyFilters();
          },
          onSubmitted: (_) => _fetchInventory(query: _searchCtrl.text),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryCtrl,
          decoration: InputDecoration(
            hintText: 'Фильтр по узлу/категории',
            prefixIcon: const Icon(Icons.category_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (_) => _applyFilters(),
          onSubmitted: (_) => _fetchInventory(query: _searchCtrl.text),
        ),
      ],
    );
  }
}
