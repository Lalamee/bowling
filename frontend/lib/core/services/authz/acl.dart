import 'dart:collection';

import '../../models/user_club.dart';
import '../../utils/user_club_resolver.dart';
import '../local_auth_storage.dart';
import '../../../models/maintenance_request_response_dto.dart';

class UserAccessScope {
  final String role;
  final Set<int> accessibleClubIds;
  final int? userId;

  const UserAccessScope({
    required this.role,
    required this.accessibleClubIds,
    this.userId,
  });

  bool get isAdmin => role == 'admin';

  String get storageKeySuffix => (userId ?? role).toString();

  bool canViewOrder(MaintenanceRequestResponseDto order) {
    if (isAdmin) return true;
    final clubId = order.clubId;
    if (clubId == null) return false;
    return accessibleClubIds.contains(clubId);
  }

  bool canViewClub(UserClub club) => canViewClubId(club.id);

  bool canViewClubId(int? clubId) {
    if (isAdmin) return true;
    if (clubId == null) return false;
    return accessibleClubIds.contains(clubId);
  }

  bool canActOnClub(UserClub club) => canViewClub(club);

  bool canActOnClubId(int? clubId) => canViewClubId(clubId);

  UserAccessScope copyWith({String? role, Set<int>? accessibleClubIds, int? userId}) {
    return UserAccessScope(
      role: role ?? this.role,
      accessibleClubIds: accessibleClubIds ?? this.accessibleClubIds,
      userId: userId ?? this.userId,
    );
  }

  static Future<UserAccessScope> fromProfile(Map<String, dynamic> profile) async {
    final resolvedRole = await _resolveRole(profile);
    final clubs = resolveUserClubs(profile);
    final ids = clubs.map((e) => e.id).toSet();
    final userId = (profile['id'] as num?)?.toInt() ?? (profile['userId'] as num?)?.toInt();
    return UserAccessScope(role: resolvedRole, accessibleClubIds: UnmodifiableSetView(ids), userId: userId);
  }
}

Future<String> _resolveRole(Map<String, dynamic> me) async {
  String? mapRole(String? value) {
    final normalized = value?.toLowerCase().trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.contains('admin') || normalized.contains('админ')) return 'admin';
    if (normalized.contains('owner') || normalized.contains('влад')) return 'owner';
    if (normalized.contains('manager') ||
        normalized.contains('менедж') ||
        normalized.contains('chief') ||
        normalized.contains('head')) {
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
    resolved =
        mapRole(role['name']?.toString()) ?? mapRole(role['roleName']?.toString()) ?? mapRole(role['key']?.toString());
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

bool canViewOrder(UserAccessScope scope, MaintenanceRequestResponseDto order) => scope.canViewOrder(order);

bool canActOnClub(UserAccessScope scope, UserClub club) => scope.canActOnClub(club);

bool canAccessClubId(UserAccessScope scope, int? clubId) => scope.canViewClubId(clubId);
