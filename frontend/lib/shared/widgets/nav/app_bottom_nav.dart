// lib/features/shared/widgets/nav/app_bottom_nav.dart
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkGray,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заказы'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Клуб'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Профиль'),
      ],
    );
  }
}
