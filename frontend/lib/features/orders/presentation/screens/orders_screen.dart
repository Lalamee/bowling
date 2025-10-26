import 'package:flutter/material.dart';

import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_auth_storage.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/models/user_club.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../domain/order_status.dart';
import '../widgets/order_status_badge.dart';
import 'order_summary_screen.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _maintenanceRepository = MaintenanceRepository();
  final _userRepository = UserRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _allRequests = [];
  List<UserClub> _clubs = const [];
  int? _selectedClubId;
  int? _selectedLane;
  int? _expandedIndex;
  _OrdersFilter _filter = _OrdersFilter.all;
  String? _role;
  final Set<int> _pendingRequestIds = <int>{};

  bool get _isMechanic => (_role ?? 'mechanic') == 'mechanic';
  bool get _isManagerLike => _role == 'manager' || _role == 'owner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 56, color: AppColors.darkGray),
                          const SizedBox(height: 12),
                          const Text(
                            'Не удалось загрузить заказы',
                            style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Повторить попытку'),
                          ),
                          TextButton(
                            onPressed: _logout,
                            child: const Text('Выйти из аккаунта'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (_clubs.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 200),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Вы не привязаны ни к одному клубу',
                            style: TextStyle(color: AppColors.darkGray, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _logout,
                            child: const Text('Выйти из аккаунта'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final requests = _filteredRequests;
              if (requests.isEmpty) {
                String emptyText;
                switch (_filter) {
                  case _OrdersFilter.archive:
                    emptyText = 'Архивных заказов нет';
                    break;
                  case _OrdersFilter.active:
                    emptyText = 'Нет текущих заказов';
                    break;
                  default:
                    emptyText = 'Заказы отсутствуют';
                    break;
                }
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 200),
                    Center(
                      child: Text(
                        emptyText,
                        style: const TextStyle(color: AppColors.darkGray, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Заказы',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _load,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _clubDropdown(),
                  if (_laneOptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _laneDropdown(),
                  ],
                  const SizedBox(height: 12),
                  _statusFilterChips(),
                  const SizedBox(height: 12),
                  ...List.generate(requests.length, (index) {
                    final request = requests[index];
                    final isExpanded = _expandedIndex == index;
                    final statusCategory = mapOrderStatus(request.status);
                    final canConfirm = _canConfirmRequest(request);
                    final confirmInProgress = _pendingRequestIds.contains(request.requestId);
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == requests.length - 1 ? 0 : 12),
                      child: _OrderCard(
                        request: request,
                        expanded: isExpanded,
                        statusCategory: statusCategory,
                        canConfirm: canConfirm,
                        confirmInProgress: confirmInProgress,
                        onToggle: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onOpenSummary: () => _openSummary(request),
                        onConfirm: canConfirm ? () => _openSummary(request) : null,
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: (!_isMechanic || _clubs.isEmpty)
          ? null
          : FloatingActionButton(
              onPressed: _openCreateRequest,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => BottomNavDirect.go(context, 0, i),
      ),
    );
  }

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
      final me = await _userRepository.me();
      final resolvedRole = await _resolveRole(me);
      if (!mounted) return;
      final clubs = resolveUserClubs(me);
      final selectedClubId = _resolveSelectedClubId(clubs, _selectedClubId);
      final requests = await _fetchRequestsForClubs(clubs);
      if (!mounted) return;
      setState(() {
        _role = resolvedRole;
        _clubs = clubs;
        _selectedClubId = selectedClubId;
        _allRequests = requests;
        final lanes = _laneOptions;
        if (!lanes.contains(_selectedLane)) {
          _selectedLane = null;
        }
        _expandedIndex = null;
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

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (route) => false);
  }

  Future<void> _openCreateRequest() async {
    if (_clubs.isEmpty) {
      showSnack(context, 'Вы не привязаны ни к одному клубу');
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      Routes.createMaintenanceRequest,
      arguments: {'clubId': _selectedClubId},
    );

    if (result == true) {
      await _load();
    }
  }

  List<int> get _laneOptions {
    final lanes = _requestsForSelectedClub
        .map((e) => e.laneNumber)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    return lanes;
  }

  List<MaintenanceRequestResponseDto> get _filteredRequests {
    var base = _requestsForSelectedClub;
    if (_filter != _OrdersFilter.all) {
      final archive = _filter == _OrdersFilter.archive;
      base = base
          .where((request) {
            final isArchived = isArchivedStatus(request.status);
            return archive ? isArchived : !isArchived;
          })
          .toList();
    }

    final selected = _selectedLane;
    if (selected != null) {
      base = base.where((element) => element.laneNumber == selected).toList();
    }
    return base;
  }

  List<MaintenanceRequestResponseDto> get _requestsForSelectedClub {
    final clubId = _selectedClubId;
    if (clubId == null) {
      return const [];
    }
    return _allRequests.where((element) => element.clubId == clubId).toList();
  }

  int? _resolveSelectedClubId(List<UserClub> clubs, int? current) {
    if (clubs.isEmpty) {
      return null;
    }
    if (current != null && clubs.any((club) => club.id == current)) {
      return current;
    }
    return clubs.first.id;
  }

  bool _canConfirmRequest(MaintenanceRequestResponseDto request) {
    if (!_isManagerLike) return false;
    return mapOrderStatus(request.status) == OrderStatusCategory.pending;
  }

  bool? _guessAvailabilityFromNotes(String? notes) {
    if (notes == null) return null;
    final normalized = notes.toLowerCase();
    if (normalized.contains('нет') && normalized.contains('детал')) {
      return false;
    }
    if (normalized.contains('есть') && normalized.contains('детал')) {
      return true;
    }
    return null;
  }

  Future<bool> _confirmRequest(
    MaintenanceRequestResponseDto request, {
    required bool partsAvailable,
    String? comment,
  }) async {
    final noteParts = <String>[
      partsAvailable ? 'Детали в наличии' : 'Деталей нет',
    ];
    if (comment != null && comment.trim().isNotEmpty) {
      noteParts.add(comment.trim());
    }
    final payload = noteParts.join('. ');

    setState(() {
      _pendingRequestIds.add(request.requestId);
    });

    try {
      final updated = await _maintenanceRepository.approve(request.requestId, payload);
      if (!mounted) return true;
      setState(() {
        _pendingRequestIds.remove(request.requestId);
        if (updated != null) {
          final index = _allRequests.indexWhere((e) => e.requestId == updated.requestId);
          if (index != -1) {
            _allRequests[index] = updated;
          } else {
            _allRequests = [..._allRequests, updated];
          }
          _sortRequests(_allRequests);
        }
      });
      if (mounted) {
        showSnack(context, 'Заказ подтверждён');
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingRequestIds.remove(request.requestId);
        });
        showApiError(context, e);
      }
      return false;
    }
  }

  Future<void> _openSummary(MaintenanceRequestResponseDto request) async {
    final canConfirm = _canConfirmRequest(request);
    final initialAvailability = _guessAvailabilityFromNotes(request.managerNotes);

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          orderNumber: 'Заявка №${request.requestId}',
          order: request,
          canConfirm: canConfirm,
          initialAvailability: initialAvailability,
          onConfirm: canConfirm
              ? ({required bool partsAvailable, String? comment}) =>
                  _confirmRequest(request, partsAvailable: partsAvailable, comment: comment)
              : null,
        ),
      ),
    );
  }

  Future<List<MaintenanceRequestResponseDto>> _fetchRequestsForClubs(List<UserClub> clubs) async {
    if (clubs.isEmpty) {
      return const [];
    }

    final responses = await Future.wait(
      clubs.map((club) => _maintenanceRepository.getRequestsByClub(club.id)),
    );

    final combined = <MaintenanceRequestResponseDto>[];
    final seen = <int>{};

    for (final list in responses) {
      for (final request in list) {
        if (seen.add(request.requestId)) {
          combined.add(request);
        }
      }
    }

    _sortRequests(combined);

    return combined;
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

  Future<String> _resolveRole(Map<String, dynamic> me) async {
    String? mapRole(String? value) {
      final normalized = value?.toLowerCase().trim();
      if (normalized == null || normalized.isEmpty) return null;
      if (normalized.contains('admin') || normalized.contains('админ')) return 'admin';
      if (normalized.contains('owner') || normalized.contains('влад')) return 'owner';
      if (normalized.contains('manager') || normalized.contains('менедж') || normalized.contains('chief') || normalized.contains('head')) {
        return 'manager';
      }
      if (normalized.contains('mechanic') || normalized.contains('механ')) return 'mechanic';
      return null;
    }

    String? resolved;

    resolved ??= mapRole(me['accountTypeName']?.toString());
    resolved ??= mapRole(me['accountType']?.toString());

    final role = me['role'];
    if (resolved == null && role is Map) {
      resolved = mapRole(role['name']?.toString()) ?? mapRole(role['roleName']?.toString()) ?? mapRole(role['key']?.toString());
    } else if (resolved == null && role is String) {
      resolved = mapRole(role);
    }

    resolved ??= mapRole(me['roleName']?.toString());
    resolved ??= mapRole(me['roleKey']?.toString());

    final roleId = (me['roleId'] as num?)?.toInt();
    if (resolved == null && roleId != null) {
      switch (roleId) {
        case 1:
          resolved = 'admin';
          break;
        case 4:
          resolved = 'mechanic';
          break;
        case 5:
          resolved = 'owner';
          break;
        case 6:
          resolved = 'manager';
          break;
      }
    }

    final accountTypeId = (me['accountTypeId'] as num?)?.toInt();
    if (resolved == null && accountTypeId != null) {
      switch (accountTypeId) {
        case 2:
          resolved = 'owner';
          break;
        case 1:
          resolved = 'mechanic';
          break;
      }
    }

    if (resolved == null) {
      final stored = await LocalAuthStorage.getRegisteredRole();
      resolved = stored?.toLowerCase();
    }

    return resolved ?? 'mechanic';
  }

  Widget _statusFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _OrdersFilter.values.map((filter) {
        final isSelected = _filter == filter;
        return ChoiceChip(
          label: Text(
            _filterLabel(filter),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.lightGray),
          onSelected: (value) {
            if (!value) return;
            setState(() {
              _filter = filter;
              _expandedIndex = null;
            });
          },
        );
      }).toList(),
    );
  }

  String _filterLabel(_OrdersFilter filter) {
    switch (filter) {
      case _OrdersFilter.active:
        return 'Текущие';
      case _OrdersFilter.archive:
        return 'Архив';
      case _OrdersFilter.all:
      default:
        return 'Все';
    }
  }

  Widget _laneDropdown() {
    final lanes = _laneOptions;
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedLane,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkGray),
          hint: const Text('Все дорожки', style: TextStyle(color: AppColors.textDark)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Все дорожки')),
            ...lanes.map(
              (lane) => DropdownMenuItem<int?>(
                value: lane,
                child: Text('Дорожка $lane', style: const TextStyle(color: AppColors.textDark)),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _selectedLane = v;
            _expandedIndex = null;
          }),
        ),
      ),
    );
  }

  Widget _clubDropdown() {
    if (_selectedClubId == null || _clubs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedClubId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkGray),
          items: _clubs
              .map(
                (club) => DropdownMenuItem<int>(
                  value: club.id,
                  child: Text(
                    club.name,
                    style: const TextStyle(color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null || value == _selectedClubId) return;
            setState(() {
              _selectedClubId = value;
              _selectedLane = null;
              _expandedIndex = null;
            });
            _load();
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MaintenanceRequestResponseDto request;
  final bool expanded;
  final OrderStatusCategory statusCategory;
  final bool canConfirm;
  final bool confirmInProgress;
  final VoidCallback onToggle;
  final VoidCallback onOpenSummary;
  final VoidCallback? onConfirm;

  const _OrderCard({
    required this.request,
    required this.expanded,
    required this.statusCategory,
    required this.canConfirm,
    required this.confirmInProgress,
    required this.onToggle,
    required this.onOpenSummary,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: expanded ? AppColors.primary : AppColors.lightGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onOpenSummary,
            title: Text(
              'Заявка №${request.requestId}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.clubName != null && request.clubName!.isNotEmpty)
                  Text(request.clubName!, style: const TextStyle(color: AppColors.darkGray)),
                if (request.laneNumber != null)
                  Text('Дорожка ${request.laneNumber}', style: const TextStyle(color: AppColors.darkGray)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OrderStatusBadge(category: statusCategory),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.darkGray),
                  ),
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (request.managerNotes != null && request.managerNotes!.isNotEmpty) ...[
                    const Text('Заметки менеджера', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(request.managerNotes!, style: const TextStyle(color: AppColors.darkGray)),
                    const SizedBox(height: 12),
                  ],
                  const Text('Детали заказа', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  if (request.requestedParts.isEmpty)
                    const Text('Нет деталей', style: TextStyle(color: AppColors.darkGray))
                  else ...request.requestedParts.map(
                      (part) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.partName ?? part.catalogNumber ?? 'Неизвестная деталь',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                            if (part.quantity != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
                              ),
                            if (part.status != null && part.status!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Статус: ${_statusName(part.status!)}', style: const TextStyle(color: AppColors.darkGray)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (canConfirm && onConfirm != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: confirmInProgress ? null : onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: confirmInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Подтвердить заказ'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onOpenSummary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Подробнее'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _statusName(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'Новая заявка';
      case 'APPROVED':
        return 'Одобрено';
      case 'REJECTED':
        return 'Отклонено';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'DONE':
        return 'Выполнено';
      case 'COMPLETED':
        return 'Завершено';
      case 'CLOSED':
        return 'Закрыто';
      case 'UNREPAIRABLE':
        return 'Неремонтопригодно';
      default:
        return 'Статус: $status';
    }
  }
}

enum _OrdersFilter { all, active, archive }
