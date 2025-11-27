import 'dart:collection';

import '../../models/user_club.dart';
import '../../utils/user_club_resolver.dart';
import '../local_auth_storage.dart';
import '../../../models/maintenance_request_response_dto.dart';

class UserAccessScope {
  final String role;
  final Set<int> accessibleClubIds;
  final int? userId;
  final bool hasPremiumAccess;
  final String? accountTypeName;
  final int? mechanicProfileId;

  const UserAccessScope({
    required this.role,
    required this.accessibleClubIds,
    this.userId,
    this.accountTypeName,
    this.mechanicProfileId,
    this.hasPremiumAccess = false,
  });

  bool get isAdmin => role == 'admin';
  bool get isMechanic => role == 'mechanic';
  bool get isFreeMechanic =>
      isMechanic && (accountTypeName?.toUpperCase().contains('FREE_MECHANIC') ?? false);

  String get storageKeySuffix => (userId ?? role).toString();

  bool canViewOrder(MaintenanceRequestResponseDto order) {
    if (isAdmin) return true;
    final clubId = order.clubId;
    if (isMechanic) {
      if (mechanicProfileId != null && order.mechanicId != null &&
          order.mechanicId == mechanicProfileId) {
        return true;
      }
      if (userId != null && order.mechanicId != null && order.mechanicId == userId) {
        return true;
      }
    }
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

  UserAccessScope copyWith({
    String? role,
    Set<int>? accessibleClubIds,
    int? userId,
    bool? hasPremiumAccess,
    String? accountTypeName,
    int? mechanicProfileId,
  }) {
    return UserAccessScope(
      role: role ?? this.role,
      accessibleClubIds: accessibleClubIds ?? this.accessibleClubIds,
      userId: userId ?? this.userId,
      accountTypeName: accountTypeName ?? this.accountTypeName,
      mechanicProfileId: mechanicProfileId ?? this.mechanicProfileId,
      hasPremiumAccess: hasPremiumAccess ?? this.hasPremiumAccess,
    );
  }

  static Future<UserAccessScope> fromProfile(Map<String, dynamic> profile) async {
    final resolvedRole = await _resolveRole(profile);
    final accountTypeName = _resolveAccountTypeName(profile);
    final clubs = resolveUserClubs(profile);
    final ids = clubs.map((e) => e.id).toSet();

    void addClubIdIfPresent(dynamic source) {
      if (source is Map) {
        final map = Map<String, dynamic>.from(source);
        final dynamic candidate =
            map['clubId'] ?? map['id'] ?? map['club'] ?? map['clubProfileId'];
        final resolved = _asInt(candidate);
        if (resolved != null) {
          ids.add(resolved);
        }
      }
    }

    if (ids.isEmpty) {
      addClubIdIfPresent(profile['managerProfile']);
      addClubIdIfPresent(profile['ownerProfile']);
      addClubIdIfPresent(profile['mechanicProfile']);
      final fallback = _asInt(profile['clubId']);
      if (fallback != null) {
        ids.add(fallback);
      }
    }

    final userId = (profile['id'] as num?)?.toInt() ?? (profile['userId'] as num?)?.toInt();
    final mechanicProfileId = _resolveMechanicProfileId(profile);
    final hasPremium = _resolvePremiumAccess(profile, resolvedRole, accountTypeName);
    return UserAccessScope(
      role: resolvedRole,
      accessibleClubIds: UnmodifiableSetView(ids),
      userId: userId,
      accountTypeName: accountTypeName,
      mechanicProfileId: mechanicProfileId,
      hasPremiumAccess: hasPremium,
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
  return null;
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

String? _resolveAccountTypeName(Map<String, dynamic> me) {
  String? accountType = me['accountTypeName']?.toString();
  accountType ??= me['accountType']?.toString();
  if (accountType != null && accountType.isNotEmpty) {
    return accountType;
  }
  final accountTypeId = (me['accountTypeId'] as num?)?.toInt();
  if (accountTypeId != null) {
    switch (accountTypeId) {
      case 1:
        return 'INDIVIDUAL';
      case 2:
        return 'CLUB_OWNER';
    }
  }
  return null;
}

int? _resolveMechanicProfileId(Map<String, dynamic> me) {
  final direct = (me['mechanicProfileId'] as num?)?.toInt();
  if (direct != null) return direct;
  final profile = me['mechanicProfile'];
  if (profile is Map) {
    final map = Map<String, dynamic>.from(profile);
    final id = (map['profileId'] as num?)?.toInt();
    if (id != null) return id;
  }
  return null;
}

bool _resolvePremiumAccess(Map<String, dynamic> me, String resolvedRole, String? accountTypeName) {
  if (resolvedRole == 'admin' || resolvedRole == 'owner' || resolvedRole == 'manager') {
    return true;
  }

  String? accessName = accountTypeName ?? me['accountTypeName']?.toString();
  accessName ??= me['accountType']?.toString();
  final normalized = accessName?.toLowerCase().trim() ?? '';
  if (normalized.contains('premium') || normalized.contains('прем')) {
    return true;
  }

  final accountTypeId = (me['accountTypeId'] as num?)?.toInt();
  if (accountTypeId != null) {
    // account_type: 1=INDIVIDUAL (механики/менеджеры), 2=CLUB_OWNER (владельцы клуба)
    if (accountTypeId == 2) {
      return true;
    }
  }

  final premiumFlag = me['isPremium'];
  if (premiumFlag is bool && premiumFlag) {
    return true;
  }

  if (premiumFlag is String) {
    final normalizedFlag = premiumFlag.toLowerCase().trim();
    if (normalizedFlag == 'true' || normalizedFlag == '1' || normalizedFlag == 'yes') {
      return true;
    }
  }

  return false;
}

bool canViewOrder(UserAccessScope scope, MaintenanceRequestResponseDto order) => scope.canViewOrder(order);

bool canActOnClub(UserAccessScope scope, UserClub club) => scope.canActOnClub(club);

bool canAccessClubId(UserAccessScope scope, int? clubId) => scope.canViewClubId(clubId);
