import 'package:flutter/material.dart';
import '../debug/test_overrides.dart';
import '../services/local_auth_storage.dart';
import '../authz/role_context_resolver.dart';
import '../authz/role_access.dart';

import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/admin_orders_screen.dart';

import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/clubs/presentation/screens/club_screen.dart';
import '../routing/routes.dart';
import '../utils/user_club_resolver.dart';

import '../../features/profile/mechanic/presentation/screens/mechanic_profile_screen.dart';
import '../../features/profile/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/profile/manager/presentation/screens/manager_profile_screen.dart';
import '../../features/profile/admin/presentation/screens/admin_profile_screen.dart';

class BottomNavDirect {
  static void go(BuildContext context, int current, int tapped) {
    if (tapped == current) return;

    () async {
      final ctx = await _resolveContext();
      final hasAccess = await _hasFullAccess(ctx);

      if (!_isTabAllowed(ctx, tapped)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Раздел недоступен для текущего типа аккаунта'),
          ),
        );
        return;
      }

      if (tapped != 3 && !hasAccess) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ к разделу откроется после подтверждения владельцем клуба'),
          ),
        );
        return;
      }

      switch (tapped) {
        case 0:
          if (ctx.role == RoleName.admin) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
          }
          break;
        case 1:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
          break;
        case 2:
          if (ctx.access.allows(AccessSection.freeWarehouse) && !ctx.access.allows(AccessSection.clubEquipment)) {
            final hasClubAccess = await _freeMechanicHasClubAccess();
            if (hasClubAccess) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClubScreen()));
            } else {
              Navigator.pushReplacementNamed(context, Routes.personalWarehouse);
            }
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClubScreen()));
          }
          break;
        case 3:
          if (ctx.role == RoleName.clubOwner) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerProfileScreen()));
          } else if (ctx.role == RoleName.headMechanic) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerProfileScreen()));
          } else if (ctx.role == RoleName.admin) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MechanicProfileScreen()));
          }
          break;
      }
    }();
  }

  static Future<RoleAccountContext> _resolveContext() async {
    if (TestOverrides.enabled) {
      final forced = RoleAccessMatrix.parseRole(TestOverrides.userRole);
      if (forced != null) {
        return RoleAccountContext(role: forced, accountType: null);
      }
    }

    final storedRole = await LocalAuthStorage.getRegisteredRole();
    final storedType = await LocalAuthStorage.getRegisteredAccountType();
    final stored = RoleContextResolver.fromStored(storedRole, storedType);
    if (stored != null) return stored;

    return const RoleAccountContext(role: RoleName.mechanic, accountType: null);
  }

  static Future<bool> _hasFullAccess(RoleAccountContext ctx) async {
    if (ctx.role == RoleName.admin || ctx.role == RoleName.clubOwner || ctx.role == RoleName.headMechanic) {
      return true;
    }

    Map<String, dynamic>? profile;

    if (ctx.role == RoleName.mechanic) {
      profile = await LocalAuthStorage.loadMechanicProfile();
    } else if (ctx.role == RoleName.headMechanic) {
      profile = await LocalAuthStorage.loadManagerProfile();
    } else {
      return true;
    }

    if (profile == null) {
      return false;
    }

    bool _boolFrom(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return false;
    }

    final verified = _boolFrom(profile['workplaceVerified']) ||
        _boolFrom(profile['isVerified']) ||
        _boolFrom(profile['verified']);

    return verified;
  }

  static bool _isTabAllowed(RoleAccountContext ctx, int tab) {
    switch (tab) {
      case 0:
        return ctx.access.allows(AccessSection.maintenance) || ctx.role == RoleName.admin;
      case 1:
        return true;
      case 2:
        return ctx.access.allows(AccessSection.clubEquipment) ||
            ctx.access.allows(AccessSection.technicalInfo) ||
            ctx.access.allows(AccessSection.freeWarehouse);
      case 3:
        return true;
      default:
        return true;
    }
  }

  static Future<bool> _freeMechanicHasClubAccess() async {
    final profile = await LocalAuthStorage.loadMechanicProfile();
    if (profile == null) return false;
    return resolveUserClubs(profile).isNotEmpty;
  }
}
