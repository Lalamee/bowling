import 'package:flutter/material.dart';

import '../../../../core/models/user_club.dart';
import '../../../../core/repositories/maintenance_repository.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/utils/user_club_resolver.dart';
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
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = true;
  bool _hasError = false;
  List<MaintenanceRequestResponseDto> _allRequests = [];
  List<UserClub> _clubs = const [];
  int? _selectedClubId;

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
      final clubs = resolveUserClubs(me);
      final selectedClub = _resolveSelectedClubId(clubs, _selectedClubId);
      final requests = await _fetchRequestsForClubs(clubs);
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _selectedClubId = selectedClub;
        _allRequests = requests;
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
    if (_clubs.isEmpty) {
      return _buildEmptyClubsState();
    }

    final requests = _filteredRequests;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _buildClubSelector(),
          const SizedBox(height: 14),
          if (requests.isEmpty)
            _buildEmptyRequestsState()
          else
            ...requests.map(_buildRequestTile),
        ],
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
              'Не удалось загрузить историю заказов',
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

  Widget _buildEmptyClubsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline, size: 48, color: AppColors.darkGray),
            SizedBox(height: 12),
            Text(
              'У вас нет привязанных клубов для просмотра истории заказов.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: const Text(
        'Заказы отсутствуют',
        style: TextStyle(color: AppColors.darkGray, fontSize: 16),
      ),
    );
  }

  Widget _buildClubSelector() {
    final items = <DropdownMenuItem<int?>>[];
    if (_clubs.length > 1) {
      items.add(const DropdownMenuItem<int?>(value: null, child: Text('Все клубы')));
    }
    items.addAll(
      _clubs.map(
        (club) => DropdownMenuItem<int?>(
          value: club.id,
          child: Text(club.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedClubId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGray),
          items: items,
          onChanged: (value) => setState(() => _selectedClubId = value),
        ),
      ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSummaryScreen(
                order: request,
                orderNumber: 'Заявка №${request.requestId}',
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

  List<MaintenanceRequestResponseDto> get _filteredRequests {
    final clubId = _selectedClubId;
    if (clubId == null) {
      return _allRequests;
    }
    return _allRequests.where((element) => element.clubId == clubId).toList();
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

  int? _resolveSelectedClubId(List<UserClub> clubs, int? current) {
    if (clubs.isEmpty) {
      return null;
    }
    if (current != null && clubs.any((club) => club.id == current)) {
      return current;
    }
    if (clubs.length == 1) {
      return clubs.first.id;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
