import 'package:flutter/material.dart';
import '../debug/test_overrides.dart';
import '../services/local_auth_storage.dart';

import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/admin_orders_screen.dart';

import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/clubs/presentation/screens/club_screen.dart';

import '../../features/profile/mechanic/presentation/screens/mechanic_profile_screen.dart';
import '../../features/profile/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/profile/manager/presentation/screens/manager_profile_screen.dart';
import '../../features/profile/admin/presentation/screens/admin_profile_screen.dart';

class BottomNavDirect {
  static void go(BuildContext context, int current, int tapped) {
    if (tapped == current) return;

    () async {
      final role = await _resolveRole();

      switch (tapped) {
        case 0:
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
          }
          break;
        case 1:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
          break;
        case 2:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClubScreen()));
          break;
        case 3:
          if (role == 'owner') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerProfileScreen()));
          } else if (role == 'manager') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerProfileScreen()));
          } else if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MechanicProfileScreen()));
          }
          break;
      }
    }();
  }

  static Future<String> _resolveRole() async {
    if (TestOverrides.enabled) {
      final forced = TestOverrides.userRole.trim().toLowerCase();
      if (forced.isNotEmpty) {
        return forced;
      }
    }

    final stored = await LocalAuthStorage.getRegisteredRole();
    final normalized = stored?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    final fallback = TestOverrides.userRole.trim().toLowerCase();
    return fallback.isNotEmpty ? fallback : 'mechanic';
  }
}
