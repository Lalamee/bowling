import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

import '../../../api/api_core.dart';
import '../../../core/repositories/maintenance_repository.dart';
import '../../../core/repositories/notifications_repository.dart';
import '../../../core/services/authz/acl.dart';
import '../../../core/services/notifications/local_notification_service.dart';
import '../../../core/services/storage/last_seen_storage.dart';
import '../../../models/maintenance_request_response_dto.dart';

class NotificationsBadgeController extends ChangeNotifier {
  static final NotificationsBadgeController _instance = NotificationsBadgeController._internal();

  factory NotificationsBadgeController() => _instance;

  NotificationsBadgeController._internal();

  final MaintenanceRepository _maintenanceRepository = MaintenanceRepository();
  final LocalNotificationService _notificationService = LocalNotificationService();
  final NotificationsRepository _notificationsRepository = NotificationsRepository();

  final List<MaintenanceRequestResponseDto> _pending = <MaintenanceRequestResponseDto>[];
  int _extraNotifications = 0;
  Timer? _pollingTimer;
  UserAccessScope? _scope;
  DateTime? _lastSeen;
  bool _isFetching = false;

  UnmodifiableListView<MaintenanceRequestResponseDto> get newOrders => UnmodifiableListView(_pending);

  int get badgeCount => _pending.length + _extraNotifications;

  DateTime? get lastSeen => _lastSeen;

  bool get isInitialized => _scope != null;

  Future<void> ensureInitialized(UserAccessScope scope) async {
    final previousKey = _scope?.storageKeySuffix;
    _scope = scope;
    if (previousKey != scope.storageKeySuffix || _lastSeen == null) {
      _lastSeen = await LastSeenStorage.getLastSeen(scope.storageKeySuffix);
      if (_lastSeen == null) {
        _lastSeen = DateTime.now();
        await LastSeenStorage.setLastSeen(scope.storageKeySuffix, _lastSeen!);
      }
    }
    _startPolling();
    await refresh();
  }

  Future<void> refresh() async {
    final scope = _scope;
    if (scope == null || _isFetching) return;

    final hasAnyAccess =
        scope.isAdmin || scope.mechanicProfileId != null || scope.accessibleClubIds.isNotEmpty;
    if (!hasAnyAccess) {
      // Нет доступа к заявкам — сбрасываем таймер и список, чтобы не спамить запросами.
      stop();
      if (_pending.isNotEmpty) {
        _pending.clear();
        notifyListeners();
      }
      return;
    }

    _isFetching = true;
    try {
      await _notificationService.init();
      final previousIds = _pending.map((item) => item.requestId).toSet();
      final orders = await _maintenanceRepository.getAllRequests();
      final accessible = orders.where(scope.canViewOrder).toList();
      accessible.sort((a, b) {
        final aDate = _resolveUpdatedAt(a);
        final bDate = _resolveUpdatedAt(b);
        if (aDate == null && bDate == null) {
          return b.requestId.compareTo(a.requestId);
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      final threshold = _lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fresh = accessible.where((order) {
        final updated = _resolveUpdatedAt(order);
        if (updated == null) return false;
        return updated.isAfter(threshold);
      }).toList();
      final newItems = fresh.where((order) => !previousIds.contains(order.requestId)).toList();
      _pending
        ..clear()
        ..addAll(fresh);
      _extraNotifications = await _countExtraNotifications(scope);
      notifyListeners();
      await _notifyAboutNewOrders(newItems);
    } on DioException catch (error, stackTrace) {
      final apiError = error.error;
      final status = error.response?.statusCode ?? (apiError is ApiException ? apiError.statusCode : null);
      final isForbidden =
          status == 401 || status == 403 || (apiError is ApiException && apiError.message.contains('Доступ запрещён'));

      if (isForbidden) {
        debugPrint('Notifications refresh skipped: unauthorized (${status ?? 'unknown'})');
        stop();
      } else {
        debugPrint('Notifications refresh failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (error, stackTrace) {
      debugPrint('Notifications refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> markAllAsRead() async {
    final scope = _scope;
    if (scope == null) return;
    final now = DateTime.now();
    _lastSeen = now;
    await LastSeenStorage.setLastSeen(scope.storageKeySuffix, now);
    if (_pending.isNotEmpty) {
      _pending.clear();
    }
    if (_extraNotifications != 0) {
      _extraNotifications = 0;
    }
    notifyListeners();
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> handleRealtimeUpdate(MaintenanceRequestResponseDto order) async {
    // TODO: wire this to WebSocket push once backend channel is available
    final scope = _scope;
    if (scope == null) return;
    if (!scope.canViewOrder(order)) return;

    _pending.removeWhere((item) => item.requestId == order.requestId);
    final updatedAt = _resolveUpdatedAt(order);
    if (_lastSeen != null && updatedAt != null && updatedAt.isBefore(_lastSeen!)) {
      return;
    }
    _pending.insert(0, order);
    notifyListeners();
    await _notificationService.showOrderNotification(order);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<int> _countExtraNotifications(UserAccessScope scope) async {
    try {
      final events = await _notificationsRepository.fetchNotifications(role: scope.role);
      final threshold = _lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      final accessibleClubIds = scope.accessibleClubIds;
      final filtered = events.where((event) {
        final created = event.createdAt;
        if (created == null || created.isBefore(threshold)) return false;
        if (event.clubId != null && accessibleClubIds.isNotEmpty && !accessibleClubIds.contains(event.clubId!)) {
          return false;
        }
        if (event.mechanicId != null && scope.mechanicProfileId != null && event.mechanicId != scope.mechanicProfileId) {
          return false;
        }
        return true;
      }).toList();
      return filtered.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _notifyAboutNewOrders(List<MaintenanceRequestResponseDto> newOrders) async {
    for (final order in newOrders) {
      await _notificationService.showOrderNotification(order);
    }
  }

  DateTime? _resolveUpdatedAt(MaintenanceRequestResponseDto order) {
    DateTime? latest;

    void consider(DateTime? candidate) {
      if (candidate == null) return;
      if (latest == null || candidate.isAfter(latest!)) {
        latest = candidate;
      }
    }

    consider(order.managerDecisionDate);
    consider(order.completionDate);
    consider(order.requestDate);

    if (order.requestedParts.any((part) => part.helpRequested == true)) {
      final helpTimestamp = order.managerDecisionDate ??
          order.requestDate ??
          DateTime.fromMillisecondsSinceEpoch(order.requestId * 1000);
      consider(helpTimestamp);
    }

    for (final part in order.requestedParts) {
      consider(part.deliveryDate);
      consider(part.issueDate);
      consider(part.orderDate);
    }

    return latest;
  }
}
