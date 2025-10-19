import 'package:flutter/material.dart';
import '../debug/test_overrides.dart';

import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/manager_orders_history_screen.dart';
import '../../features/orders/presentation/screens/admin_orders_screen.dart';

import '../../features/clubs/presentation/screens/club_screen.dart';

import '../../features/profile/mechanic/presentation/screens/mechanic_profile_screen.dart';
import '../../features/profile/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/profile/manager/presentation/screens/manager_profile_screen.dart';
import '../../features/profile/admin/presentation/screens/admin_profile_screen.dart';

class BottomNavDirect {
  static void go(BuildContext context, int current, int tapped) {
    if (tapped == current) return;

    final role = TestOverrides.userRole.toLowerCase();

    switch (tapped) {
      case 0:
        if (role == 'manager') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerOrdersHistoryScreen()));
        } else if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
        }
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const _CatalogStub()));
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
  }
}

class _CatalogStub extends StatelessWidget {
  const _CatalogStub({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: Center(child: Text('Каталог'))));
  }
}
