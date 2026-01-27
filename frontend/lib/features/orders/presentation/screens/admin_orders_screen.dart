import 'package:flutter/material.dart';

import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../models/club_summary_dto.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../domain/order_status.dart';
import '../widgets/order_status_badge.dart';
import 'order_summary_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final MaintenanceRepository _maintenanceRepository = MaintenanceRepository();
  final ClubsRepository _clubsRepository = ClubsRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<_ClubOrdersSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final requestsFuture = _maintenanceRepository.getAllRequests();
      final clubsFuture = _clubsRepository.getClubs();
      final requests = await requestsFuture;
      final clubs = await clubsFuture;

      if (!mounted) return;

      setState(() {
        _sections = _buildSections(clubs, requests);
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

  List<_ClubOrdersSection> _buildSections(
    List<ClubSummaryDto> clubs,
    List<MaintenanceRequestResponseDto> requests,
  ) {
    final sections = <int?, _ClubOrdersSection>{};

    for (final club in clubs) {
      final id = club.id;
      final name = _resolveClubName(id, club.name);
      sections[id] = _ClubOrdersSection(clubId: id, clubName: name, orders: []);
    }

    for (final request in requests) {
      final key = request.clubId;
      final resolvedName = _resolveClubName(key, request.clubName);
      final section = sections.putIfAbsent(
        key,
        () => _ClubOrdersSection(clubId: key, clubName: resolvedName, orders: []),
      );
      if (section.clubName.trim().isEmpty || section.clubName.startsWith('Клуб #')) {
        section.clubName = resolvedName;
      }
      section.orders.add(request);
    }

    final list = sections.values.toList();
    for (final section in list) {
      _sortRequests(section.orders);
      section.isOpen = section.orders.isNotEmpty;
    }
    list.sort((a, b) => a.clubName.toLowerCase().compareTo(b.clubName.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, Routes.profileAdmin);
            }
          },
        ),
        title: const Text(
          'История заказов',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return _buildErrorState();
    }
    if (_sections.isEmpty) {
      return _buildEmptyRequestsState();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildSectionCard(_sections[index], index),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.darkGray),
            const SizedBox(height: 12),
            const Text(
              'Не удалось загузить историю заказов',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.darkGray),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline, size: 48, color: AppColors.darkGray),
            SizedBox(height: 12),
            Text(
              'Заказы отсутствуют',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(_ClubOrdersSection section, int index) {
    final borderColor = section.isOpen ? AppColors.primary : AppColors.lightGray;
    final orderCount = section.orders.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(index),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.clubName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Всего заказов: $orderCount',
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    section.isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.darkGray,
                  ),
                ],
              ),
            ),
          ),
          if (section.isOpen) const Divider(height: 1),
          if (section.isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildSectionContent(section),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(_ClubOrdersSection section) {
    if (section.orders.isEmpty) {
      return const Text('Заказы отсутствуют', style: TextStyle(color: AppColors.darkGray));
    }

    return Column(
      children: section.orders.map(_buildRequestTile).toList(),
    );
  }

  Widget _buildRequestTile(MaintenanceRequestResponseDto request) {
    final subtitle = <String>[];
    if (request.clubName != null && request.clubName!.isNotEmpty) {
      subtitle.add(request.clubName!);
    }
    if (request.laneNumber != null) {
      subtitle.add('Дорожка ${request.laneNumber}');
    }
    if (request.requestDate != null) {
      subtitle.add(_formatDate(request.requestDate!));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          final canConfirm = mapOrderStatus(request.status) == OrderStatusCategory.pending;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSummaryScreen(
                order: request,
                orderNumber: 'Заявка №${request.requestId}',
                canConfirm: canConfirm,
                onConfirm: canConfirm
                    ? ({required Map<int, bool> availability, String? comment}) =>
                        _confirmRequest(request, availability: availability, comment: comment)
                    : null,
                onOrderUpdated: _replaceOrder,
              ),
            ),
          );
        },
        title: Text(
          'Заявка №${request.requestId}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle.join(' • '),
                style: const TextStyle(color: AppColors.darkGray),
              ),
        trailing: OrderStatusBadge.fromRaw(request.status),
      ),
    );
  }

  void _toggleSection(int index) {
    setState(() {
      _sections[index].isOpen = !_sections[index].isOpen;
    });
  }

  void _sortRequests(List<MaintenanceRequestResponseDto> list) {
    list.sort((a, b) {
      final aDate = a.requestDate;
      final bDate = b.requestDate;
      if (aDate == null && bDate == null) {
        return b.requestId.compareTo(a.requestId);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
  }

  Future<bool> _confirmRequest(
    MaintenanceRequestResponseDto request, {
    required Map<int, bool> availability,
    String? comment,
  }) async {
    final noteParts = <String>[];
    if (availability.isNotEmpty) {
      final partsById = {for (final part in request.requestedParts) part.partId: part};
      final available = <String>[];
      final unavailable = <String>[];
      availability.forEach((partId, isAvailable) {
        final part = partsById[partId];
        final name = part?.partName ?? part?.catalogNumber ?? 'Деталь $partId';
        if (isAvailable) {
          available.add(name);
        } else {
          unavailable.add(name);
        }
      });
      if (available.isNotEmpty && unavailable.isEmpty) {
        noteParts.add('Все детали в наличии');
      } else if (unavailable.isNotEmpty && available.isEmpty) {
        noteParts.add('Деталей нет в наличии');
      } else {
        if (available.isNotEmpty) {
          noteParts.add('В наличии: ${available.join(', ')}');
        }
        if (unavailable.isNotEmpty) {
          noteParts.add('Нет: ${unavailable.join(', ')}');
        }
      }
    }
    if (comment != null && comment.trim().isNotEmpty) {
      noteParts.add(comment.trim());
    }
    final payload = noteParts.isEmpty ? null : noteParts.join('. ');

    try {
      final updated = await _maintenanceRepository.approve(request.requestId, availability, payload);
      if (!mounted) return true;
      if (updated != null) {
        _replaceOrder(updated);
      }
      if (mounted) {
        showSnack(context, 'Заказ подтверждён');
      }
      return true;
    } catch (e) {
      if (mounted) {
        showApiError(context, e);
      }
      return false;
    }
  }

  void _replaceOrder(MaintenanceRequestResponseDto updated) {
    final updatedId = updated.requestId;
    final updatedClubId = updated.clubId;
    final updatedClubName = _resolveClubName(updatedClubId, updated.clubName);
    setState(() {
      _ClubOrdersSection? sourceSection;
      for (final section in _sections) {
        final index = section.orders.indexWhere((order) => order.requestId == updatedId);
        if (index != -1) {
          section.orders.removeAt(index);
          sourceSection = section;
          break;
        }
      }
      if (sourceSection != null && sourceSection.orders.isEmpty) {
        sourceSection.isOpen = false;
      }
      final target = _sections.firstWhere(
        (section) => section.clubId == updatedClubId,
        orElse: () {
          final created = _ClubOrdersSection(
            clubId: updatedClubId,
            clubName: updatedClubName,
            orders: [],
            isOpen: true,
          );
          _sections.add(created);
          return created;
        },
      );
      if (target.clubName.trim().isEmpty || target.clubName.startsWith('Клуб #')) {
        target.clubName = updatedClubName;
      }
      target.orders.add(updated);
      _sortRequests(target.orders);
      _sections.sort((a, b) => a.clubName.toLowerCase().compareTo(b.clubName.toLowerCase()));
    });
  }

  String _resolveClubName(int? clubId, String? provided) {
    final name = provided?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (clubId == null) {
      return 'Без привязки к клубу';
    }
    return 'Клуб #$clubId';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _ClubOrdersSection {
  final int? clubId;
  String clubName;
  final List<MaintenanceRequestResponseDto> orders;
  bool isOpen;

  _ClubOrdersSection({
    required this.clubId,
    required this.clubName,
    required this.orders,
    this.isOpen = false,
  });
}
