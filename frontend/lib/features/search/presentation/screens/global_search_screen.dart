import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/search_repository.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/global_search_response_dto.dart';
import '../../../../models/part_dto.dart';
import '../../../../shared/widgets/inputs/adaptive_text.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  static const _limitPerSection = 6;

  final _repository = SearchRepository();
  final _searchCtrl = TextEditingController();
  final _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

  Timer? _debounce;
  bool _isLoading = true;
  bool _hasError = false;
  GlobalSearchResponseDto? _results;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }

  Future<void> _load(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await _repository.searchGlobal(query, limit: _limitPerSection);
      if (!mounted) return;
      setState(() {
        _results = res;
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

  Future<void> _refresh() => _load(_searchCtrl.text);

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
          'Поиск',
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
                      onSubmitted: _load,
                      decoration: const InputDecoration(
                        hintText: 'Введите запрос по каталогу, заявкам или клубам',
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
                    onPressed: () => _load(_searchCtrl.text),
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
            const Text('Не удалось выполнить поиск', style: TextStyle(color: AppColors.darkGray)),
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

    final data = _results;
    if (data == null || _isEmpty(data)) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: AppColors.darkGray),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: _buildSections(data),
      ),
    );
  }

  bool _isEmpty(GlobalSearchResponseDto data) {
    return data.parts.isEmpty &&
        data.maintenanceRequests.isEmpty &&
        data.workLogs.isEmpty &&
        data.clubs.isEmpty;
  }

  List<Widget> _buildSections(GlobalSearchResponseDto data) {
    final sections = <_SearchSection<dynamic>>[
      _SearchSection<PartDto>(
        title: 'Запчасти',
        icon: Icons.handyman_outlined,
        items: data.parts,
        itemBuilder: (part) => _PartResultTile(part: part),
      ),
      _SearchSection<SearchMaintenanceRequestDto>(
        title: 'Заявки на обслуживание',
        icon: Icons.assignment_outlined,
        items: data.maintenanceRequests,
        itemBuilder: (req) => _MaintenanceRequestTile(
          request: req,
          formatter: _dateFormatter,
        ),
      ),
      _SearchSection<SearchWorkLogDto>(
        title: 'Рабочие журналы',
        icon: Icons.work_history_outlined,
        items: data.workLogs,
        itemBuilder: (log) => _WorkLogResultTile(
          log: log,
          formatter: _dateFormatter,
        ),
      ),
      _SearchSection<SearchClubDto>(
        title: 'Клубы',
        icon: Icons.storefront_outlined,
        items: data.clubs,
        itemBuilder: (club) => _ClubResultTile(club: club),
      ),
    ].where((section) => section.items.isNotEmpty).toList();

    final children = <Widget>[];
    for (final section in sections) {
      children.add(_SectionHeader(title: section.title, icon: section.icon, count: section.items.length));
      children.add(const SizedBox(height: 8));
      children.addAll(section.items.map(section.itemBuilder));
      children.add(const SizedBox(height: 20));
    }

    if (children.isNotEmpty) {
      children.removeLast();
    }

    return children;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SearchSection<T> {
  final String title;
  final IconData icon;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  _SearchSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.itemBuilder,
  });
}

class _PartResultTile extends StatelessWidget {
  final PartDto part;

  const _PartResultTile({required this.part});

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
      margin: const EdgeInsets.only(bottom: 12),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
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

class _MaintenanceRequestTile extends StatelessWidget {
  final SearchMaintenanceRequestDto request;
  final DateFormat formatter;

  const _MaintenanceRequestTile({required this.request, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заявка №${request.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              if (request.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status!,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (request.clubName != null)
            _InfoRow(icon: Icons.store_mall_directory_outlined, text: request.clubName!),
          if (request.laneNumber != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.alt_route, text: 'Дорожка: ${request.laneNumber}'),
          ],
          if (request.mechanicName != null && request.mechanicName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.engineering_outlined, text: request.mechanicName!),
          ],
          if (request.requestedAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.schedule_outlined, text: formatter.format(request.requestedAt!.toLocal())),
          ],
        ],
      ),
    );
  }
}

class _WorkLogResultTile extends StatelessWidget {
  final SearchWorkLogDto log;
  final DateFormat formatter;

  const _WorkLogResultTile({required this.log, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Журнал №${log.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
              if (log.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.status!,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (log.clubName != null)
            _InfoRow(icon: Icons.store_outlined, text: log.clubName!),
          if (log.workType != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.category_outlined, text: log.workType!),
          ],
          if (log.laneNumber != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.alt_route, text: 'Дорожка: ${log.laneNumber}'),
          ],
          if (log.mechanicName != null && log.mechanicName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.engineering_outlined, text: log.mechanicName!),
          ],
          if (log.problemDescription != null && log.problemDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.problemDescription!,
              style: const TextStyle(color: AppColors.darkGray),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (log.createdAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.schedule_outlined, text: formatter.format(log.createdAt!.toLocal())),
          ],
        ],
      ),
    );
  }
}

class _ClubResultTile extends StatelessWidget {
  final SearchClubDto club;

  const _ClubResultTile({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name ?? 'Клуб №${club.id}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          if (club.address != null && club.address!.trim().isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: club.address!),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (club.active != null)
                _StatusChip(
                  label: club.active! ? 'Активен' : 'Не активен',
                  color: club.active! ? AppColors.primary : AppColors.darkGray,
                ),
              if (club.verified != null)
                _StatusChip(
                  label: club.verified! ? 'Верифицирован' : 'Не верифицирован',
                  color: club.verified! ? Colors.green : AppColors.darkGray,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.darkGray),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.darkGray),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
