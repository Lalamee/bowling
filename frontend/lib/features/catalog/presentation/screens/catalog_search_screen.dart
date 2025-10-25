import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/part_dto.dart';
import '../../../../shared/widgets/inputs/adaptive_text.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';

class CatalogSearchScreen extends StatefulWidget {
  const CatalogSearchScreen({super.key});

  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> {
  final _repository = InventoryRepository();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  bool _hasError = false;
  List<PartDto> _results = const [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // update clear button visibility
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String rawQuery) async {
    final query = rawQuery.trim();
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _repository.search(query);
      if (!mounted) return;
      setState(() {
        _results = data;
        _isLoading = false;
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

  Future<void> _refresh() => _search(_searchCtrl.text);

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Каталог',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Поиск по каталогу',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGray, size: 20),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: () => _search(_searchCtrl.text),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) => BottomNavDirect.go(context, 1, i),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text(
              'Не удалось загрузить каталог',
              style: TextStyle(color: AppColors.darkGray),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final part = _results[index];
          return _CatalogItemTile(part: part);
        },
      ),
    );
  }
}

class _CatalogItemTile extends StatelessWidget {
  final PartDto part;

  const _CatalogItemTile({required this.part});

  String get _title {
    final candidates = [part.commonName, part.officialNameRu, part.officialNameEn];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return part.catalogNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDEDED), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptiveText(
            _title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text('Каталожный №: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
          if (part.quantity != null) ...[
            const SizedBox(height: 4),
            Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
          ],
          if (part.location != null && part.location!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Локация: ${part.location}', style: const TextStyle(color: AppColors.darkGray)),
          ],
        ],
      ),
    );
  }
}
