import 'package:flutter/material.dart';

import '../../../../../core/repositories/maintenance_repository.dart';
import '../../../../../core/repositories/user_repository.dart';
import '../../../../../core/services/favorites_storage.dart';
import '../../../../../core/services/authz/acl.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../orders/presentation/screens/order_summary_screen.dart';
import '../../../../../models/maintenance_request_response_dto.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesStorage _storage = FavoritesStorage();
  final MaintenanceRepository _maintenanceRepository = MaintenanceRepository();
  final UserRepository _userRepository = UserRepository();

  bool _loadingOrders = true;
  bool _loadingParts = true;
  List<MaintenanceRequestResponseDto> _orders = const [];
  List<FavoritePart> _parts = const [];
  Set<int> _orderIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await Future.wait([_loadFavoriteOrders(), _loadFavoriteParts()]);
  }

  Future<void> _loadFavoriteOrders() async {
    setState(() => _loadingOrders = true);
    final ids = await _storage.loadFavoriteOrders();
    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _orderIds = ids;
        _orders = const [];
        _loadingOrders = false;
      });
      return;
    }

    final resolved = <int, MaintenanceRequestResponseDto>{};
    try {
      final me = await _userRepository.me();
      final scope = await UserAccessScope.fromProfile(me);
      if (scope.isAdmin) {
        final all = await _maintenanceRepository.getAllRequests();
        for (final order in all) {
          if (ids.contains(order.requestId)) {
            resolved[order.requestId] = order;
          }
        }
      } else if (scope.isMechanic && scope.mechanicProfileId != null) {
        final own = await _maintenanceRepository.requestsForMechanic(scope.mechanicProfileId!);
        for (final order in own) {
          if (ids.contains(order.requestId)) {
            resolved[order.requestId] = order;
          }
        }
      } else if (scope.accessibleClubIds.isNotEmpty) {
        for (final clubId in scope.accessibleClubIds) {
          final clubOrders = await _maintenanceRepository.getRequestsByClub(clubId);
          for (final order in clubOrders) {
            if (ids.contains(order.requestId)) {
              resolved[order.requestId] = order;
            }
          }
        }
      }
    } catch (_) {
      resolved.clear();
    }

    for (final id in ids) {
      if (!resolved.containsKey(id)) {
        final order = await _maintenanceRepository.getById(id);
        if (order != null) {
          resolved[id] = order;
        }
      }
    }

    final orders = resolved.values.toList()
      ..sort((a, b) => b.requestId.compareTo(a.requestId));
    if (!mounted) return;
    setState(() {
      _orderIds = ids;
      _orders = orders;
      _loadingOrders = false;
    });
  }

  Future<void> _loadFavoriteParts() async {
    setState(() => _loadingParts = true);
    final parts = await _storage.loadFavoriteParts();
    if (!mounted) return;
    setState(() {
      _parts = parts;
      _loadingParts = false;
    });
  }

  Future<void> _toggleFavoriteOrder(int orderId) async {
    await _storage.toggleFavoriteOrder(orderId);
    await _loadFavoriteOrders();
  }

  Future<void> _removeFavoritePart(String key) async {
    await _storage.removeFavoritePart(key);
    await _loadFavoriteParts();
  }

  void _openOrder(MaintenanceRequestResponseDto order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          orderNumber: 'Заявка №${order.requestId}',
          order: order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Избранные заказы/детали'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Заказы'),
              Tab(text: 'Детали'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadFavoriteOrders,
              child: _loadingOrders
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Избранных заказов пока нет')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (_, index) {
                            final order = _orders[index];
                            return ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text('Заявка №${order.requestId}'),
                              subtitle: Text(order.clubName ?? 'Без клуба'),
                              trailing: IconButton(
                                icon: const Icon(Icons.star, color: Colors.amber),
                                onPressed: () => _toggleFavoriteOrder(order.requestId),
                              ),
                              onTap: () => _openOrder(order),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: _orders.length,
                        ),
            ),
            RefreshIndicator(
              onRefresh: _loadFavoriteParts,
              child: _loadingParts
                  ? const Center(child: CircularProgressIndicator())
                  : _parts.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Избранных деталей пока нет')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (_, index) {
                            final part = _parts[index];
                            return ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text(part.name),
                              subtitle: part.catalogNumber != null && part.catalogNumber!.isNotEmpty
                                  ? Text('Кат. №: ${part.catalogNumber}')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.star, color: Colors.amber),
                                onPressed: () => _removeFavoritePart(part.key),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: _parts.length,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
