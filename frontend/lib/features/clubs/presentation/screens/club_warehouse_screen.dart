import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../shared/widgets/layout/common_ui.dart';
import '../widgets/lane_card.dart';
import '../widgets/position_card.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/part_dto.dart';
import 'club_search_screen.dart';
import '../../../../shared/widgets/inputs/adaptive_text.dart';

class ClubWarehouseScreen extends StatefulWidget {
  final int clubId;
  final String? clubName;

  const ClubWarehouseScreen({Key? key, required this.clubId, this.clubName}) : super(key: key);

  @override
  State<ClubWarehouseScreen> createState() => _ClubWarehouseScreenState();
}

class _ClubWarehouseScreenState extends State<ClubWarehouseScreen> {
  final _repo = InventoryRepository();
  final _cellCtrl = TextEditingController();
  final _shelfCtrl = TextEditingController();
  final _markCtrl = TextEditingController();
  String _selectedItem = '';
  final _searchCtrl = TextEditingController();
  List<PartDto> _inventory = [];
  PartDto? _selectedPart;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _cellCtrl.dispose();
    _shelfCtrl.dispose();
    _markCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _repo.search('', clubId: widget.clubId);
      if (!mounted) return;
      _applyInventory(data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  Future<void> _searchInventory(String query) async {
    if (query.isEmpty) {
      _loadInventory();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _repo.search(query, clubId: widget.clubId);
      if (!mounted) return;
      _applyInventory(data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      showApiError(context, e);
    }
  }

  Future<void> _openSearchOverlay() async {
    final res = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ClubSearchScreen(query: _searchCtrl.text)),
    );
    if (res != null && res.isNotEmpty) {
      final match = _findPartByName(res);
      if (match != null) {
        _selectPart(match);
      } else {
        setState(() {
          _searchCtrl.text = res;
        });
        _searchInventory(res);
      }
    }
  }

  void _applyInventory(List<PartDto> data) {
    final selected = _resolveSelected(data);
    setState(() {
      _inventory = data;
      _selectedPart = selected;
      _selectedItem = selected != null ? _partDisplayName(selected) : '';
      _isLoading = false;
      _hasError = false;
    });
    _fillControllers(selected);
  }

  PartDto? _resolveSelected(List<PartDto> data) {
    if (data.isEmpty) return null;
    final current = _selectedPart;
    if (current != null) {
      for (final part in data) {
        if (part.inventoryId == current.inventoryId) {
          return part;
        }
      }
    }
    return data.first;
  }

  void _selectPart(PartDto part) {
    setState(() {
      _selectedPart = part;
      _selectedItem = _partDisplayName(part);
    });
    _fillControllers(part);
  }

  PartDto? _findPartByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final part in _inventory) {
      if (_partDisplayName(part).toLowerCase() == normalized) {
        return part;
      }
    }
    return null;
  }

  String _partDisplayName(PartDto part) {
    final candidates = [
      part.commonName,
      part.officialNameRu,
      part.officialNameEn,
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return part.catalogNumber;
  }

  void _fillControllers(PartDto? part) {
    if (part == null) {
      _cellCtrl.text = '';
      _shelfCtrl.text = '';
      _markCtrl.text = '';
      return;
    }
    final location = part.location?.trim();
    _cellCtrl.text = location != null && location.isNotEmpty ? location : '';
    _shelfCtrl.text = part.catalogNumber;
    _markCtrl.text = part.quantity?.toString() ?? '';
  }

  Map<String, List<PartDto>> _groupInventory() {
    final map = <String, List<PartDto>>{};
    for (final part in _inventory) {
      final location = part.location?.trim() ?? '';
      final key = location.isEmpty ? 'Без указания локации' : location;
      map.putIfAbsent(key, () => []).add(part);
    }
    return map;
  }

  List<Widget> _buildInventoryCards() {
    final groups = _groupInventory().entries.toList();
    if (groups.isEmpty) {
      return const [];
    }
    return List.generate(groups.length, (index) {
      final entry = groups[index];
      final parts = entry.value;
      return LaneCard(
        title: entry.key,
        initiallyOpen: index == 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(parts.length, (i) {
            final part = parts[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == parts.length - 1 ? 0 : 8),
              child: _InventoryItemTile(
                title: _partDisplayName(part),
                part: part,
                selected: _selectedPart?.inventoryId == part.inventoryId,
                onTap: () => _selectPart(part),
              ),
            );
          }),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clubName != null && widget.clubName!.trim().isNotEmpty
        ? 'Склад: ${widget.clubName}'
        : 'Склад';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const Spacer(),
                IconButton(onPressed: _loadInventory, icon: const Icon(Icons.sync, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _searchInventory,
                      decoration: const InputDecoration(
                        hintText: 'Поиск',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(onPressed: _openSearchOverlay, icon: const Icon(Icons.search, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CommonUI.card(
              padding: const EdgeInsets.all(12),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _hasError
                      ? Column(
                          children: [
                            const Icon(Icons.cloud_off, size: 56, color: AppColors.darkGray),
                            const SizedBox(height: 12),
                            const Text(
                              'Не удалось загрузить склад',
                              style: TextStyle(color: AppColors.darkGray),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadInventory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Повторить'),
                            ),
                          ],
                        )
                      : _inventory.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'На складе пока нет данных',
                                  style: TextStyle(color: AppColors.darkGray),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_selectedPart != null) ...[
                                  PositionCard(
                                    selected: true,
                                    title: _selectedItem.isEmpty ? 'Выберите позицию' : _selectedItem,
                                    onEdit: _openSearchOverlay,
                                    cellCtrl: _cellCtrl,
                                    shelfCtrl: _shelfCtrl,
                                    markCtrl: _markCtrl,
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                ..._buildInventoryCards(),
                              ],
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final String title;
  final PartDto part;
  final bool selected;
  final VoidCallback onTap;

  const _InventoryItemTile({
    Key? key,
    required this.title,
    required this.part,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const subtitleStyle = TextStyle(fontSize: 13, color: AppColors.darkGray);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFEDEDED), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveText(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textDark,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            Text('Каталожный №: ${part.catalogNumber}', style: subtitleStyle),
            if (part.quantity != null) ...[
              const SizedBox(height: 4),
              Text('Количество: ${part.quantity}', style: subtitleStyle),
            ],
            if (part.location != null && part.location!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Локация: ${part.location}', style: subtitleStyle),
            ],
          ],
        ),
      ),
    );
  }
}
