import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/notifications_service.dart';
import '../../../core/theme/colors.dart';
import '../badge_icon.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  final NotificationsServiceImpl _notifications = NotificationsServiceImpl();
  StreamSubscription<int>? _badgeSub;
  int _badge = 0;

  @override
  void initState() {
    super.initState();
    _badgeSub = _notifications.badgeCount().listen((count) {
      if (!mounted) return;
      if (_badge != count) {
        setState(() => _badge = count);
      }
    });
  }

  @override
  void dispose() {
    _badgeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkGray,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заказы'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
        BottomNavigationBarItem(
          icon: BadgeIcon(
            child: const Icon(Icons.notifications_none_outlined),
            count: _badge,
          ),
          label: 'Оповещения',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Клубы'),
        const BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Профиль'),
      ],
    );
  }
}
