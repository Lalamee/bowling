import 'dart:async';

import '../models/user_roles.dart';
import '../repositories/user_repository.dart';
import '../utils/user_club_resolver.dart';
import 'local_auth_storage.dart';

abstract class AccessGuard {
  Set<String> allowedClubIdsForCurrent();
  bool canAccessClub(String clubId);
  bool isAdmin();
}

class AccessSnapshot {
  final UserRole role;
  final Set<String> allowedClubIds;
  final Map<String, dynamic>? rawProfile;
  final int? userId;
  final DateTime updatedAt;

  const AccessSnapshot({
    required this.role,
    required this.allowedClubIds,
    required this.rawProfile,
    required this.userId,
    required this.updatedAt,
  });

  bool canAccess(String? clubId) {
    if (clubId == null || clubId.isEmpty) {
      return role.isAdmin;
    }
    if (role.isAdmin) {
      return true;
    }
    return allowedClubIds.contains(clubId);
  }
}

class AccessGuardImpl implements AccessGuard {
  AccessGuardImpl._internal();

  static final AccessGuardImpl _instance = AccessGuardImpl._internal();
  factory AccessGuardImpl() => _instance;

  final UserRepository _userRepository = UserRepository();
  final StreamController<AccessSnapshot> _controller = StreamController.broadcast();

  AccessSnapshot? _snapshot;
  Future<AccessSnapshot>? _inFlight;

  Stream<AccessSnapshot> get changes => _controller.stream;

  Future<AccessSnapshot> ensureLoaded() async {
    if (_snapshot != null) {
      return _snapshot!;
    }
    return refresh();
  }

  Future<AccessSnapshot> refresh() {
    final currentInFlight = _inFlight;
    if (currentInFlight != null) {
      return currentInFlight;
    }
    final completer = Completer<AccessSnapshot>();
    _inFlight = completer.future;

    () async {
      try {
        final storedRole = await LocalAuthStorage.getRegisteredRole();
        Map<String, dynamic>? profile;
        try {
          profile = await _userRepository.me();
        } catch (_) {
          profile = null;
        }
        final role = UserRoleResolver.fromProfile(profile, storedRole: storedRole);
        final allowed = _resolveAllowedClubs(profile);
        final snapshot = AccessSnapshot(
          role: role,
          allowedClubIds: allowed,
          rawProfile: profile,
          userId: _resolveUserId(profile),
          updatedAt: DateTime.now(),
        );
        _snapshot = snapshot;
        _controller.add(snapshot);
        completer.complete(snapshot);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _inFlight = null;
      }
    }();

    return completer.future;
  }

  void updateProfile(Map<String, dynamic>? profile, {String? roleHint}) {
    final role = UserRoleResolver.fromProfile(profile, storedRole: roleHint);
    final allowed = _resolveAllowedClubs(profile);
    final snapshot = AccessSnapshot(
      role: role,
      allowedClubIds: allowed,
      rawProfile: profile,
      userId: _resolveUserId(profile),
      updatedAt: DateTime.now(),
    );
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  int? _resolveUserId(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final value = profile['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Set<String> _resolveAllowedClubs(Map<String, dynamic>? profile) {
    if (profile == null) {
      return const <String>{};
    }
    final resolved = resolveUserClubs(profile);
    final ids = <String>{};
    for (final club in resolved) {
      final id = club.id.toString();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }

  @override
  Set<String> allowedClubIdsForCurrent() {
    return _snapshot?.allowedClubIds ?? const <String>{};
  }

  @override
  bool canAccessClub(String clubId) {
    if (clubId.isEmpty) return isAdmin();
    final snapshot = _snapshot;
    if (snapshot == null) {
      return false;
    }
    return snapshot.role.isAdmin || snapshot.allowedClubIds.contains(clubId);
  }

  @override
  bool isAdmin() {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return false;
    }
    return snapshot.role.isAdmin;
  }
}
