import 'package:flutter/material.dart';

import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/clubs_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/favorites_storage.dart';
import '../../../../core/services/local_auth_storage.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
import '../../../../core/models/user_club.dart';
import '../../../../models/maintenance_request_response_dto.dart';
import '../../../../models/club_summary_dto.dart';
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
  final _clubsRepository = ClubsRepository();
  final _favoritesStorage = FavoritesStorage();

  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _allRequests = [];
  List<UserClub> _clubs = const [];
  List<ClubSummaryDto> _availableClubs = const [];
  int? _selectedClubId;
  int? _selectedLane;
  int? _expandedIndex;
  _OrdersFilter _filter = _OrdersFilter.all;
  String? _role;
  int? _mechanicProfileId;
  bool _isFreeMechanic = false;
  final Set<int> _pendingRequestIds = <int>{};
  Set<int> _favoriteOrderIds = <int>{};

  bool get _isMechanic => (_role ?? 'mechanic') == 'mechanic';
  bool get _isManagerLike => _role == 'manager' || _role == 'owner';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true;
        }
        _handleBackFallback();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: BackButton(onPressed: _handleBackPress),
          title: const Text(
            'Заказы',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _load,
            ),
          ],
        ),
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
                    if (_clubs.isNotEmpty) _clubDropdown(),
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
                      final canComplete = _canCompleteRequest(request);
                      final actionInProgress = _pendingRequestIds.contains(request.requestId);
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == requests.length - 1 ? 0 : 12),
                        child: _OrderCard(
                          request: request,
                          expanded: isExpanded,
                          statusCategory: statusCategory,
                          canConfirm: canConfirm,
                          canComplete: canComplete,
                          actionInProgress: actionInProgress,
                          isFavorite: _favoriteOrderIds.contains(request.requestId),
                          onToggle: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          onOpenSummary: () => _openSummary(request),
                          onToggleFavorite: () => _toggleFavorite(request.requestId),
                          onConfirm: canConfirm ? () => _openSummary(request) : null,
                          onComplete: canComplete
                              ? () {
                                  _completeRequest(request);
                                }
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: (!_isMechanic || (_clubs.isEmpty && _availableClubs.isEmpty))
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoritesStorage.loadFavoriteOrders();
    if (!mounted) return;
    setState(() {
      _favoriteOrderIds = ids;
    });
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
      final isFreeMechanic = _resolveFreeMechanicFlag(me);
      final mechanicProfileId = _extractMechanicProfileId(me);
      final availableClubs = resolvedRole == 'mechanic' && clubs.isEmpty
          ? await _clubsRepository.getClubs()
          : const <ClubSummaryDto>[];
      final selectedClubId = _resolveSelectedClubId(clubs, _selectedClubId);
      final requests = await _fetchRequestsForClubs(
        clubs,
        mechanicProfileId,
        includeMechanicRequests: isFreeMechanic,
        loadAllRequests: resolvedRole == 'admin',
      );
      if (!mounted) return;
      setState(() {
        _role = resolvedRole;
        _clubs = clubs;
        _availableClubs = availableClubs;
        _selectedClubId = selectedClubId;
        _isFreeMechanic = isFreeMechanic;
        _mechanicProfileId = mechanicProfileId;
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

  void _handleBackPress() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _handleBackFallback();
  }

  void _handleBackFallback() {
    if (!mounted) {
      return;
    }
    final role = _role ?? 'mechanic';
    if (role == 'owner') {
      Navigator.pushReplacementNamed(context, Routes.profileOwner);
    } else if (role == 'manager') {
      Navigator.pushReplacementNamed(context, Routes.profileManager);
    } else if (role == 'admin') {
      Navigator.pushReplacementNamed(context, Routes.profileAdmin);
    } else {
      Navigator.pushReplacementNamed(context, Routes.profileMechanic);
    }
  }

  Future<void> _openCreateRequest() async {
    int? selectedClubId = _selectedClubId;
    if (_clubs.isEmpty) {
      if (_isFreeMechanic) {
        selectedClubId = null;
      } else if (_availableClubs.isEmpty) {
        showSnack(context, 'Нет доступных клубов для создания заявки');
        return;
      }
      if (!_isFreeMechanic) {
        selectedClubId = await _pickClubForRequest();
        if (selectedClubId == null) return;
      }
    }

    final result = await Navigator.pushNamed(
      context,
      Routes.createMaintenanceRequest,
      arguments: {'clubId': selectedClubId},
    );

    if (result == true) {
      await _load();
    }
  }

  Future<int?> _pickClubForRequest() async {
    int? selectedId = _availableClubs.isNotEmpty ? _availableClubs.first.id : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выберите клуб'),
        content: DropdownButtonFormField<int?>(
          value: selectedId,
          decoration: const InputDecoration(labelText: 'Клуб'),
          items: _availableClubs
              .map((club) => DropdownMenuItem<int?>(
                    value: club.id,
                    child: Text(club.name ?? 'Клуб ${club.id}'),
                  ))
              .toList(),
          onChanged: (value) => selectedId = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Продолжить')),
        ],
      ),
    );
    if (confirmed != true) return null;
    return selectedId;
  }

  Future<void> _toggleFavorite(int orderId) async {
    await _favoritesStorage.toggleFavoriteOrder(orderId);
    await _loadFavorites();
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
      return _allRequests;
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

  bool _resolveFreeMechanicFlag(Map<String, dynamic>? me) {
    final accountType = me?['accountType']?.toString().toUpperCase();
    return accountType != null && accountType.contains('FREE_MECHANIC');
  }

  bool _canConfirmRequest(MaintenanceRequestResponseDto request) {
    if (mapOrderStatus(request.status) != OrderStatusCategory.pending) {
      return false;
    }
    if (_role == 'admin') return true;
    if (_isManagerLike) return request.clubId != null;
    return false;
  }

  int? _extractMechanicProfileId(Map<String, dynamic>? me) {
    if (me == null) return null;
    final direct = me['mechanicProfileId'];
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct);
    final profile = me['mechanicProfile'];
    if (profile is Map) {
      final map = Map<String, dynamic>.from(profile);
      final candidates = [map['profileId'], map['id']];
      for (final candidate in candidates) {
        if (candidate is num) return candidate.toInt();
        if (candidate is String) {
          final parsed = int.tryParse(candidate);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  bool _canCompleteRequest(MaintenanceRequestResponseDto request) {
    if (!_isMechanic) return false;
    if (_isFreeMechanic) return false;
    final status = request.status;
    if (status == null) return false;
    final resolved = OrderStatusType.fromRaw(status);
    return resolved == OrderStatusType.confirmed;
  }

  bool _canRequestHelp(MaintenanceRequestResponseDto request) {
    if (!_isMechanic) return false;
    return !isArchivedStatus(request.status) && request.requestedParts.isNotEmpty;
  }

  bool _canResolveHelp(MaintenanceRequestResponseDto request) {
    return _isManagerLike || (_role == 'admin');
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

    setState(() {
      _pendingRequestIds.add(request.requestId);
    });

    try {
      final updated = await _maintenanceRepository.approve(request.requestId, availability, payload);
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

  Future<bool> _completeRequest(MaintenanceRequestResponseDto request) async {
    setState(() {
      _pendingRequestIds.add(request.requestId);
    });

    try {
      final updated = await _maintenanceRepository.complete(request.requestId);
      if (!mounted) {
        return true;
      }

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
        showSnack(context, 'Заказ завершён и перемещён в архив');
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingRequestIds.remove(request.requestId);
        });
        showApiError(context, e);
      } else {
        _pendingRequestIds.remove(request.requestId);
      }
      return false;
    }
  }

  Future<void> _openSummary(MaintenanceRequestResponseDto request) async {
    final canConfirm = _canConfirmRequest(request);
    final canComplete = _canCompleteRequest(request);
    final canRequestHelp = _canRequestHelp(request);
    final canResolveHelp = _canResolveHelp(request);
    final initialAvailability = _guessAvailabilityFromNotes(request.managerNotes);

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          orderNumber: 'Заявка №${request.requestId}',
          order: request,
          canConfirm: canConfirm,
          canComplete: canComplete,
          canRequestHelp: canRequestHelp,
          canResolveHelp: canResolveHelp,
          initialAvailability: initialAvailability,
          onConfirm: canConfirm
              ? ({required Map<int, bool> availability, String? comment}) =>
                  _confirmRequest(request, availability: availability, comment: comment)
              : null,
          onComplete: canComplete ? () => _completeRequest(request) : null,
          onOrderUpdated: _replaceOrder,
        ),
      ),
    );
  }

  void _replaceOrder(MaintenanceRequestResponseDto updated) {
    if (!mounted) return;
    setState(() {
      final index = _allRequests.indexWhere((e) => e.requestId == updated.requestId);
      if (index != -1) {
        _allRequests[index] = updated;
      } else {
        _allRequests = [..._allRequests, updated];
      }
      _sortRequests(_allRequests);
    });
  }

  Future<List<MaintenanceRequestResponseDto>> _fetchRequestsForClubs(
    List<UserClub> clubs,
    int? mechanicProfileId, {
    bool includeMechanicRequests = false,
    bool loadAllRequests = false,
  }) async {
    if (loadAllRequests) {
      final response = await _maintenanceRepository.getAllRequests();
      _sortRequests(response);
      return response;
    }
    final includeMechanic = includeMechanicRequests && mechanicProfileId != null;
    if (clubs.isEmpty) {
      if (!includeMechanic) {
        return const [];
      }
      final response = await _maintenanceRepository.requestsForMechanic(mechanicProfileId!);
      _sortRequests(response);
      return response;
    }

    final futures = <Future<List<MaintenanceRequestResponseDto>>>[
      ...clubs.map((club) => _maintenanceRepository.getRequestsByClub(club.id)),
      if (includeMechanic) _maintenanceRepository.requestsForMechanic(mechanicProfileId!),
    ];

    final responses = await Future.wait(futures);

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
  final bool canComplete;
  final bool actionInProgress;
  final bool isFavorite;
  final VoidCallback onToggle;
  final VoidCallback onOpenSummary;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;

  const _OrderCard({
    required this.request,
    required this.expanded,
    required this.statusCategory,
    required this.canConfirm,
    required this.canComplete,
    required this.actionInProgress,
    required this.isFavorite,
    required this.onToggle,
    required this.onOpenSummary,
    required this.onToggleFavorite,
    this.onConfirm,
    this.onComplete,
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
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : AppColors.darkGray,
                  ),
                  onPressed: onToggleFavorite,
                ),
                OrderStatusBadge(category: statusCategory),
                if (request.requestedParts.any((part) => part.helpRequested == true)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Запрос помощи',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
                            if (part.catalogNumber != null && part.catalogNumber!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Каталожный номер: ${part.catalogNumber}', style: const TextStyle(color: AppColors.darkGray)),
                              ),
                            if (part.inventoryLocation != null && part.inventoryLocation!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Локация: ${part.inventoryLocation}', style: const TextStyle(color: AppColors.darkGray)),
                              ),
                            if (part.quantity != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Количество: ${part.quantity}', style: const TextStyle(color: AppColors.darkGray)),
                              ),
                            if (part.status != null && part.status!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Статус: ${describeOrderStatus(part.status)}',
                                    style: const TextStyle(color: AppColors.darkGray)),
                              ),
                            if (part.available != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Наличие: ${part.available! ? 'есть в наличии' : 'нет в наличии'}',
                                  style: const TextStyle(color: AppColors.darkGray),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (request.completionDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Завершено: ${_formatDate(request.completionDate!)}',
                      style: const TextStyle(color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (canConfirm && onConfirm != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: actionInProgress ? null : onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: actionInProgress
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
                  if (canComplete && onComplete != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: actionInProgress
                            ? null
                            : () {
                                onComplete!();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: actionInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Завершить заказ'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

}

enum _OrdersFilter { all, active, archive }
