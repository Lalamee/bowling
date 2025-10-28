import 'package:flutter/foundation.dart';

enum UserRole {
  admin('admin'),
  owner('owner'),
  manager('manager'),
  mechanic('mechanic'),
  unknown('unknown');

  final String code;
  const UserRole(this.code);

  bool get isAdmin => this == UserRole.admin;
  bool get isOwner => this == UserRole.owner;
  bool get isManager => this == UserRole.manager;
  bool get isMechanic => this == UserRole.mechanic;
  bool get hasLimitedClubs => !isAdmin;

  static UserRole fromCode(String? value) {
    if (value == null) return UserRole.unknown;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return UserRole.unknown;
    for (final role in UserRole.values) {
      if (role.code == normalized) {
        return role;
      }
    }
    switch (normalized) {
      case 'administrator':
      case 'administration':
      case 'adminstrator':
      case 'administraor':
      case 'администратор':
      case 'админ':
        return UserRole.admin;
      case 'owner':
      case 'owner_account':
      case 'владелец':
      case 'собственник':
        return UserRole.owner;
      case 'manager':
      case 'staff':
      case 'clubmanager':
      case 'head':
      case 'менеджер':
      case 'управляющий':
        return UserRole.manager;
      case 'mechanic':
      case 'engineer':
      case 'техник':
      case 'механик':
        return UserRole.mechanic;
    }
    return UserRole.unknown;
  }

  @override
  String toString() => describeEnum(this);
}

class UserRoleResolver {
  static UserRole fromProfile(Map<String, dynamic>? profile, {String? storedRole}) {
    final stored = UserRole.fromCode(storedRole);
    if (stored != UserRole.unknown) {
      return stored;
    }

    final normalizedRole = _normalize(profile?['role']);
    if (normalizedRole != null) {
      final byRole = UserRole.fromCode(normalizedRole);
      if (byRole != UserRole.unknown) {
        return byRole;
      }
    }

    final normalizedRoleName = _normalize(profile?['roleName']);
    if (normalizedRoleName != null) {
      final byRoleName = UserRole.fromCode(normalizedRoleName);
      if (byRoleName != UserRole.unknown) {
        return byRoleName;
      }
    }

    final normalizedAccountType = _normalize(profile?['accountType']);
    if (normalizedAccountType != null) {
      final byType = UserRole.fromCode(normalizedAccountType);
      if (byType != UserRole.unknown) {
        return byType;
      }
    }

    final normalizedAccountTypeName = _normalize(profile?['accountTypeName']);
    if (normalizedAccountTypeName != null) {
      final byTypeName = UserRole.fromCode(normalizedAccountTypeName);
      if (byTypeName != UserRole.unknown) {
        return byTypeName;
      }
    }

    final roleId = _toInt(profile?['roleId']);
    if (roleId != null) {
      switch (roleId) {
        case 1:
          return UserRole.admin;
        case 4:
          return UserRole.mechanic;
        case 5:
          return UserRole.owner;
        case 6:
          return UserRole.manager;
      }
    }

    final accountTypeId = _toInt(profile?['accountTypeId']);
    if (accountTypeId != null) {
      switch (accountTypeId) {
        case 1:
          return UserRole.mechanic;
        case 2:
          return UserRole.owner;
      }
    }

    return UserRole.unknown;
  }

  static String? _normalize(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim().toLowerCase();
    if (raw.isEmpty) return null;
    return raw;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
