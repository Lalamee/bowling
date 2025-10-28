import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/orders/domain/order_status.dart';
import '../../models/maintenance_request_response_dto.dart';
import '../repositories/maintenance_repository.dart';
import '../services/access_guard.dart';

abstract class NotificationsService {
  Stream<int> badgeCount();
  Future<List<MaintenanceRequestResponseDto>> fetchNewOrders({int page = 1});
  Future<void> markAllSeen();
}

class NotificationsServiceImpl implements NotificationsService {
  NotificationsServiceImpl._internal();

  static final NotificationsServiceImpl _instance = NotificationsServiceImpl._internal();
  factory NotificationsServiceImpl() => _instance;

  static const _pageSize = 20;
  static const _pollInterval = Duration(seconds: 45);

  final AccessGuardImpl _accessGuard = AccessGuardImpl();
  final MaintenanceRepository _maintenanceRepository = MaintenanceRepository();
  final StreamController<int> _badgeController = StreamController<int>.broadcast();

  StreamSubscription<AccessSnapshot>? _accessSubscription;
  Timer? _pollTimer;
  bool _initialised = false;
  bool _loading = false;
  List<MaintenanceRequestResponseDto> _cachedOrders = const [];
  _LastSeenData? _lastSeen;

  @override
  Stream<int> badgeCount() {
    _ensureInitialised();
    return _badgeController.stream;
  }

  @override
  Future<List<MaintenanceRequestResponseDto>> fetchNewOrders({int page = 1}) async {
    _ensureInitialised();
    await _ensureLatestData();
    if (page <= 1) {
      return _cachedOrders.take(_pageSize).toList();
    }
    final start = (page - 1) * _pageSize;
    if (start >= _cachedOrders.length) {
      return const [];
    }
    final end = (start + _pageSize).clamp(0, _cachedOrders.length);
    return _cachedOrders.sublist(start, end);
  }

  @override
  Future<void> markAllSeen() async {
    _ensureInitialised();
    await _ensureLatestData();
    final snapshot = await _accessGuard.ensureLoaded();
    final latest = _cachedOrders.isNotEmpty ? _cachedOrders.first : null;
    final data = _LastSeenData(
      requestId: latest?.requestId,
      timestamp: latest?.requestDate ?? DateTime.now(),
    );
    await _persistLastSeen(snapshot.userId, data);
    _lastSeen = data;
    _emitBadge();
  }

  void _ensureInitialised() {
    if (_initialised) return;
    _initialised = true;
    _badgeController.add(0);
    _accessSubscription = _accessGuard.changes.listen((_) => _refresh());
    _accessGuard.ensureLoaded().then((_) => _refresh());
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  Future<void> _ensureLatestData() async {
    if (_loading) {
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    if (_cachedOrders.isEmpty) {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_loading) {
      return;
    }
    _loading = true;
    try {
      final snapshot = await _accessGuard.ensureLoaded();
      if (!snapshot.role.isAdmin && snapshot.allowedClubIds.isEmpty) {
        _cachedOrders = const [];
        _emitBadge();
        return;
      }
      final raw = await _maintenanceRepository.getAllRequests();
      final filtered = <MaintenanceRequestResponseDto>[];
      for (final order in raw) {
        final clubId = order.clubId?.toString();
        if (!snapshot.role.isAdmin && (clubId == null || !snapshot.allowedClubIds.contains(clubId))) {
          continue;
        }
        if (!isPendingStatus(order.status)) {
          continue;
        }
        filtered.add(order);
      }
      filtered.sort((a, b) {
        final aDate = a.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.requestDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = bDate.compareTo(aDate);
        if (cmp != 0) return cmp;
        return b.requestId.compareTo(a.requestId);
      });
      _cachedOrders = filtered;
      _lastSeen ??= await _loadLastSeen(snapshot.userId);
      _emitBadge();
    } finally {
      _loading = false;
    }
  }

  void _emitBadge() {
    final count = _computeBadgeCount();
    _badgeController.add(count);
  }

  int _computeBadgeCount() {
    if (_cachedOrders.isEmpty) {
      return 0;
    }
    final lastSeen = _lastSeen;
    if (lastSeen == null) {
      return _cachedOrders.length.clamp(0, 99);
    }
    var count = 0;
    for (final order in _cachedOrders) {
      if (_isNewer(order, lastSeen)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool _isNewer(MaintenanceRequestResponseDto order, _LastSeenData lastSeen) {
    final orderDate = order.requestDate;
    if (orderDate != null && lastSeen.timestamp != null) {
      if (orderDate.isAfter(lastSeen.timestamp!)) {
        return true;
      }
      if (orderDate.isAtSameMomentAs(lastSeen.timestamp!)) {
        if (lastSeen.requestId == null) {
          return true;
        }
        return order.requestId > lastSeen.requestId!;
      }
      return false;
    }
    if (lastSeen.requestId == null) {
      return true;
    }
    return order.requestId > lastSeen.requestId!;
  }

  Future<_LastSeenData?> _loadLastSeen(int? userId) async {
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return _LastSeenData(
          requestId: _tryParseInt(map['requestId']),
          timestamp: _parseDate(map['timestamp']),
        );
      }
      if (map is Map) {
        return _LastSeenData(
          requestId: _tryParseInt(map['requestId']),
          timestamp: _parseDate(map['timestamp']),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _persistLastSeen(int? userId, _LastSeenData data) async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'requestId': data.requestId,
      'timestamp': data.timestamp?.toIso8601String(),
    });
    await prefs.setString(_storageKey(userId), payload);
  }

  String _storageKey(int userId) => 'notifications:last_seen:$userId';

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _LastSeenData {
  final int? requestId;
  final DateTime? timestamp;

  const _LastSeenData({this.requestId, this.timestamp});
}
