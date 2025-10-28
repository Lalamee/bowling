import 'package:flutter/material.dart';

import '../../../../core/repositories/search_repository.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../knowledge_base/domain/kb_pdf.dart';
import '../../../search/application/search_controller.dart';
import '../../../search/domain/search_item.dart';
import '../../presentation/widgets/search_item_tile.dart';
import '../../../../shared/widgets/highlight_text.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/part_dto.dart';
import '../../../../core/services/search_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key, this.repository});

  final SearchRepository? repository;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final SearchController _controller;
  late final TextEditingController _queryController;
  late final ScrollController _scrollController;
  late final SearchRepository _repository;
  final MaintenanceRepository _maintenanceRepository = MaintenanceRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SearchRepository();
    _controller = SearchController(repository: _repository)..restore();
    _queryController = TextEditingController(text: _controller.state.query);
    _scrollController = ScrollController()..addListener(_handleScroll);
    if (_controller.state.query.trim().isNotEmpty &&
        _controller.state.items.isEmpty &&
        !_controller.state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.submit());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _queryController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: _buildSearchField(state),
          ),
          body: Column(
            children: [
              _DomainChips(
                selected: state.domain,
                onSelected: _controller.selectDomain,
              ),
              Expanded(child: _buildBody(state)),
              if (!state.isLoading && !state.hasError && !state.isIdle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Найдено ${state.totalCount} результатов',
                    style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: 1,
            onTap: (index) => BottomNavDirect.go(context, 1, index),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(SearchState state) {
    final isLoading = state.isLoading && !state.isLoadingMore;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              onChanged: (value) => _controller.updateQuery(value),
              onSubmitted: (_) => _controller.submit(),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Поиск по заказам, запчастям, клубам…',
                border: InputBorder.none,
              ),
            ),
          ),
          if (state.query.trim().isNotEmpty && !isLoading)
            IconButton(
              onPressed: () {
                _queryController.clear();
                _controller.updateQuery('', immediate: true);
              },
              icon: const Icon(Icons.clear_rounded, color: AppColors.darkGray, size: 20),
            ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: () => _controller.submit(),
              icon: const Icon(Icons.search, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isIdle) {
      return const Center(
        child: Text(
          'Введите запрос, чтобы начать поиск',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    if (state.hasError) {
      return _ErrorState(
        message: 'Не удалось выполнить поиск',
        onRetry: _controller.refresh,
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    final items = state.items;
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = items[index];
          return SearchItemTile(
            item: item,
            query: state.query,
            onTap: () => _openItem(item),
          );
        },
      ),
    );
  }

  Future<void> _openItem(SearchItem item) async {
    try {
      switch (item.domain) {
        case SearchDomain.orders:
          final MaintenanceRequestResponseDto? order = await _repository.getOrderById(item.id) ??
              await _maintenanceRepository.getById(int.tryParse(item.id) ?? 0);
          if (!mounted) return;
          Navigator.pushNamed(
            context,
            Routes.orderSummary,
            arguments: OrderSummaryArgs(order: order, orderNumber: item.title),
          );
          break;
        case SearchDomain.parts:
          final part = await _loadPart(item.id);
          if (!mounted || part == null) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PartDetailsPage(part: part)));
          break;
        case SearchDomain.clubs:
          final club = await _repository.getClubById(item.id);
          if (!mounted || club == null) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ClubPreviewPage(club: club)));
          break;
        case SearchDomain.knowledge:
          final doc = await _repository.getDocumentById(item.id);
          if (!mounted || doc == null) return;
          Navigator.pushNamed(context, Routes.pdfReader, arguments: PdfReaderArgs(document: doc));
          break;
        case SearchDomain.users:
          final user = await _repository.getUserById(item.id);
          if (!mounted || user == null) return;
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _UserPreview(user: user),
          );
          break;
        case SearchDomain.all:
          break;
      }
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error);
    }
  }

  Future<PartDto?> _loadPart(String id) async {
    final catalogPart = await _repository.getPartById(id);
    if (catalogPart != null) {
      return PartDto(
        inventoryId: catalogPart.catalogId,
        catalogId: catalogPart.catalogId,
        catalogNumber: catalogPart.catalogNumber,
        officialNameEn: catalogPart.officialNameEn,
        officialNameRu: catalogPart.officialNameRu,
        commonName: catalogPart.commonName,
        description: catalogPart.description,
        quantity: catalogPart.availableQuantity,
        warehouseId: null,
        location: null,
        isUnique: catalogPart.isUnique,
        lastChecked: null,
      );
    }
    return _inventoryRepository.getById(id);
  }
}

class _DomainChips extends StatelessWidget {
  const _DomainChips({required this.selected, required this.onSelected});

  final SearchDomain selected;
  final ValueChanged<SearchDomain> onSelected;

  @override
  Widget build(BuildContext context) {
    final domains = SearchDomain.values;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final domain = domains[index];
          final isSelected = domain == selected;
          return ChoiceChip(
            label: Text(domain.label),
            selected: isSelected,
            onSelected: (_) => onSelected(domain),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.darkGray),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _PartDetailsPage extends StatelessWidget {
  const _PartDetailsPage({required this.part});

  final PartDto part;

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
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Каталожный номер', value: part.catalogNumber),
          if (part.description?.isNotEmpty ?? false)
            _InfoTile(label: 'Описание', value: part.description!),
          if (part.quantity != null)
            _InfoTile(label: 'Доступно', value: part.quantity.toString()),
          if (part.location?.isNotEmpty ?? false)
            _InfoTile(label: 'Локация', value: part.location!),
        ],
      ),
    );
  }
}

class _ClubPreviewPage extends StatelessWidget {
  const _ClubPreviewPage({required this.club});

  final ClubSummaryDto club;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(club.name ?? 'Клуб #${club.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Город', value: club.city ?? '—'),
          _InfoTile(label: 'Адрес', value: club.address ?? '—'),
          _InfoTile(label: 'Телефон', value: club.contactPhone ?? '—'),
        ],
      ),
    );
  }
}

class _UserPreview extends StatelessWidget {
  const _UserPreview({required this.user});

  final SearchUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${user.roleLabel} · ${user.clubName}', style: const TextStyle(color: AppColors.darkGray)),
          const SizedBox(height: 12),
          if (user.phone != null)
            _InfoTile(label: 'Телефон', value: user.phone!),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          HighlightText(
            text: value,
            highlight: null,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

